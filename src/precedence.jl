"""
Mutable state shared by a checked message codec and all of its repeating-group
flyweights.

This type is runtime support for code generated with
`precedence_checks=true`. Unchecked generated code does not reference it.
"""
mutable struct CodecStatePointer
    value::UInt16
    CodecStatePointer(value::Integer=0) = new(UInt16(value))
end

"""
    PrecedenceError

Exception thrown by generated checked codecs when a field, repeating group, or
variable-length data field is accessed out of schema order.
"""
struct PrecedenceError <: Exception
    action::String
    operation::String
    state::String
    expected::Tuple
    machine::String
end

function Base.showerror(io::IO, error::PrecedenceError)
    print(
        io,
        "Illegal field access order: cannot ",
        error.action,
        " \"",
        error.operation,
        "\" in state ",
        error.state,
        ". Expected one of: [",
        join(error.expected, ", "),
        "]. State machine: ",
        error.machine,
        ".",
    )
end

Base.@noinline function throw_precedence_error(
    action::String,
    operation::String,
    state::UInt16,
    state_names::Tuple,
    state_transitions::Tuple,
    machine::String,
)
    index = Int(state) + 1
    state_name = 1 <= index <= length(state_names) ?
        state_names[index] : "UNKNOWN($(Int(state)))"
    expected = 1 <= index <= length(state_transitions) ?
        state_transitions[index] : ()
    throw(PrecedenceError(action, operation, state_name, expected, machine))
end

const PrecedenceInteractionKey = Tuple{Symbol, String}

struct PrecedenceTransition
    from::Vector{Int}
    to::Int
end

mutable struct FieldPrecedenceModel
    state_names::Vector{String}
    transitions::Dict{PrecedenceInteractionKey, Vector{PrecedenceTransition}}
    examples::Dict{PrecedenceInteractionKey, String}
    actions::Dict{PrecedenceInteractionKey, String}
    expected_by_state::Vector{Vector{String}}
    wrapped_states::Dict{Int, Int}
    latest_wrapped_state::Int
    terminal_states::Vector{Int}
    top_level_block_fields::Set{String}
    machine_name::String
end

function FieldPrecedenceModel(machine_name::String)
    return FieldPrecedenceModel(
        String[],
        Dict{PrecedenceInteractionKey, Vector{PrecedenceTransition}}(),
        Dict{PrecedenceInteractionKey, String}(),
        Dict{PrecedenceInteractionKey, String}(),
        Vector{Vector{String}}(),
        Dict{Int, Int}(),
        0,
        Int[],
        Set{String}(),
        machine_name,
    )
end

@inline precedence_qualified_name(parent_path::String, name::String) =
    isempty(parent_path) ? name : string(parent_path, ".", name)

@inline precedence_field_key(path::String) = (:field, path)
@inline precedence_group_empty_key(path::String) = (:group_empty, path)
@inline precedence_group_nonempty_key(path::String) = (:group_nonempty, path)
@inline precedence_group_next_key(path::String) = (:group_next, path)
@inline precedence_group_last_key(path::String) = (:group_last, path)
@inline precedence_group_reset_key(path::String) = (:group_reset, path)
@inline precedence_var_data_length_key(path::String) = (:var_data_length, path)
@inline precedence_wrap_key(version::Int) = (:wrap, string(version))

function precedence_state_component(name::String)
    component = uppercase(replace(name, r"[^A-Za-z0-9]" => "_"))
    return isempty(component) ? "FIELD" : component
end

function allocate_precedence_state!(model::FieldPrecedenceModel, name::String)
    length(model.state_names) <= typemax(UInt16) ||
        error("precedence state machine exceeds UInt16 state capacity")
    push!(model.state_names, name)
    push!(model.expected_by_state, String[])
    return length(model.state_names) - 1
end

function allocate_precedence_transition!(
    model::FieldPrecedenceModel,
    key::PrecedenceInteractionKey,
    example::String,
    action::String,
    from_states,
    to_state::Int,
)
    from = sort!(unique!(collect(Int, from_states)))
    transition = PrecedenceTransition(from, to_state)
    push!(get!(Vector{PrecedenceTransition}, model.transitions, key), transition)
    model.examples[key] = example
    model.actions[key] = action
    for state in from
        expected = model.expected_by_state[state + 1]
        example in expected || push!(expected, example)
    end
    return transition
end

function precedence_split_components(
    tokens::Vector{IR.Token},
    signal::IR.Signal.T,
    start_index::Int,
)
    components = Vector{Vector{IR.Token}}()
    index = start_index
    while index <= length(tokens)
        token = tokens[index]
        token.signal == signal || break
        count = token.component_token_count
        push!(components, tokens[index:(index + count - 1)])
        index += count
    end
    return components, index
end

function precedence_group_components(group_tokens::Vector{IR.Token})
    dimension_count = group_tokens[2].component_token_count
    body_start = 2 + dimension_count
    fields, index = precedence_split_components(
        group_tokens,
        IR.Signal.BEGIN_FIELD,
        body_start,
    )
    groups, index = precedence_split_components(
        group_tokens,
        IR.Signal.BEGIN_GROUP,
        index,
    )
    var_data, _ = precedence_split_components(
        group_tokens,
        IR.Signal.BEGIN_VAR_DATA,
        index,
    )
    return fields, groups, var_data
end

function collect_precedence_versions!(
    versions::Set{Int},
    fields::Vector{Vector{IR.Token}},
    groups::Vector{Vector{IR.Token}},
    var_data::Vector{Vector{IR.Token}},
)
    for field_tokens in fields
        push!(versions, field_tokens[1].version)
    end
    for group_tokens in groups
        push!(versions, group_tokens[1].version)
        group_fields, group_groups, group_var_data =
            precedence_group_components(group_tokens)
        collect_precedence_versions!(
            versions,
            group_fields,
            group_groups,
            group_var_data,
        )
    end
    for var_data_tokens in var_data
        push!(versions, var_data_tokens[1].version)
    end
    return versions
end

function collect_top_level_block_fields!(
    model::FieldPrecedenceModel,
    fields::Vector{Vector{IR.Token}},
)
    for field_tokens in fields
        push!(model.top_level_block_fields, field_tokens[1].name)
    end
    return model
end

function collect_precedence_transitions!(
    model::FieldPrecedenceModel,
    state_prefix::String,
    parent_path::String,
    initial_states,
    block_state::Int,
    version::Int,
    fields::Vector{Vector{IR.Token}},
    groups::Vector{Vector{IR.Token}},
    var_data::Vector{Vector{IR.Token}},
)
    current_states = Set{Int}(initial_states)
    push!(current_states, block_state)

    for field_tokens in fields
        field_token = field_tokens[1]
        field_token.version <= version || continue
        path = precedence_qualified_name(parent_path, field_token.name)
        allocate_precedence_transition!(
            model,
            precedence_field_key(path),
            string(path, "(?)"),
            "access field",
            current_states,
            block_state,
        )
    end

    for group_tokens in groups
        group_token = group_tokens[1]
        group_token.version <= version || continue

        group_path = precedence_qualified_name(parent_path, group_token.name)
        group_component = precedence_state_component(group_token.name)
        group_prefix = string(state_prefix, group_component, "_")
        n_remaining = allocate_precedence_state!(model, string(group_prefix, "N"))
        n_block = allocate_precedence_state!(model, string(group_prefix, "N_BLOCK"))
        one_block = allocate_precedence_state!(model, string(group_prefix, "1_BLOCK"))
        done = allocate_precedence_state!(model, string(group_prefix, "DONE"))

        begin_states = copy(current_states)
        allocate_precedence_transition!(
            model,
            precedence_group_empty_key(group_path),
            string(group_path, "Count(0)"),
            "select count for repeating group",
            begin_states,
            done,
        )
        allocate_precedence_transition!(
            model,
            precedence_group_nonempty_key(group_path),
            string(group_path, "Count(>0)"),
            "select count for repeating group",
            begin_states,
            n_remaining,
        )

        group_fields, group_groups, group_var_data =
            precedence_group_components(group_tokens)

        n_exit = collect_precedence_transitions!(
            model,
            string(group_prefix, "N_"),
            group_path,
            Set([n_block]),
            n_block,
            version,
            group_fields,
            group_groups,
            group_var_data,
        )

        next_states = Set([n_remaining])
        union!(next_states, n_exit)
        allocate_precedence_transition!(
            model,
            precedence_group_next_key(group_path),
            string(group_path, ".next()"),
            "access next element in repeating group",
            next_states,
            n_block,
        )
        allocate_precedence_transition!(
            model,
            precedence_group_last_key(group_path),
            string(group_path, ".next()"),
            "access next element in repeating group",
            next_states,
            one_block,
        )

        one_exit = collect_precedence_transitions!(
            model,
            string(group_prefix, "1_"),
            group_path,
            Set([one_block]),
            one_block,
            version,
            group_fields,
            group_groups,
            group_var_data,
        )

        reset_states = Set([done, n_remaining])
        union!(reset_states, n_exit)
        union!(reset_states, one_exit)
        allocate_precedence_transition!(
            model,
            precedence_group_reset_key(group_path),
            string(group_path, ".resetCountToIndex()"),
            "reset count of repeating group",
            reset_states,
            done,
        )

        empty!(current_states)
        push!(current_states, done)
        union!(current_states, one_exit)
    end

    for var_data_tokens in var_data
        token = var_data_tokens[1]
        token.version <= version || continue
        path = precedence_qualified_name(parent_path, token.name)
        length_key = precedence_var_data_length_key(path)
        for state in current_states
            allocate_precedence_transition!(
                model,
                length_key,
                string(path, "Length()"),
                "inspect variable-data length",
                (state,),
                state,
            )
        end

        done = allocate_precedence_state!(
            model,
            string(state_prefix, precedence_state_component(token.name), "_DONE"),
        )
        allocate_precedence_transition!(
            model,
            precedence_field_key(path),
            string(path, "(?)"),
            "access field",
            current_states,
            done,
        )
        empty!(current_states)
        push!(current_states, done)
    end

    return current_states
end

function build_field_precedence_model(
    message_tokens::Vector{IR.Token},
    machine_name::String;
    latest_version_only::Bool,
)
    message_token = message_tokens[1]
    body = collect(IR.get_message_body(message_tokens))
    fields, index = precedence_split_components(body, IR.Signal.BEGIN_FIELD, 1)
    groups, index = precedence_split_components(body, IR.Signal.BEGIN_GROUP, index)
    var_data, _ = precedence_split_components(body, IR.Signal.BEGIN_VAR_DATA, index)

    versions = Set([message_token.version])
    collect_precedence_versions!(versions, fields, groups, var_data)
    selected_versions = sort!(collect(versions))
    latest_version_only && (selected_versions = [last(selected_versions)])

    model = FieldPrecedenceModel(machine_name)
    not_wrapped = allocate_precedence_state!(model, "NOT_WRAPPED")
    collect_top_level_block_fields!(model, fields)

    for version in selected_versions
        block_state = allocate_precedence_state!(model, "V$(version)_BLOCK")
        model.wrapped_states[version] = block_state
        allocate_precedence_transition!(
            model,
            precedence_wrap_key(version),
            "wrap(version=$version)",
            "wrap codec",
            (not_wrapped,),
            block_state,
        )
        terminal = collect_precedence_transitions!(
            model,
            "V$(version)_",
            "",
            Set([block_state]),
            block_state,
            version,
            fields,
            groups,
            var_data,
        )
        model.latest_wrapped_state = block_state
        model.terminal_states = sort!(collect(terminal))
    end

    return model
end
