"""
Compare SBE.jl with an upstream SbeTool fixture checkout.

The check covers:
- byte-for-byte synchronization of all upstream XML fixtures vendored under `test/resources`;
- schema accept/reject parity; and
- normalized IR metadata and token parity for every accepted schema; and
- the upstream relative-XInclude parser case with XInclude enabled in both tools.

Usage:
    julia --project=. scripts/check_sbetool_schema_compat.jl \
        /path/to/simple-binary-encoding/sbe-tool/src/test/resources \
        /path/to/sbe-all-<version>.jar
"""

using SBE

function schema_files(resources_dir::AbstractString)
    files = String[]
    for (root, _, names) in walkdir(resources_dir)
        append!(files, joinpath.(root, filter(name -> endswith(name, ".xml"), names)))
    end
    return sort!(files)
end

function sbejl_accepts(schema_path::AbstractString)
    try
        schema = SBE.parse_xml_schema(read(schema_path, String); suppress_warnings=true)
        return true, SBE.generate_ir(schema)
    catch error
        return false, error
    end
end

function sbetool_result(
    schema_path::AbstractString,
    jar_path::AbstractString,
    output_dir::AbstractString,
    ;
    xinclude::Bool=false,
)
    command_args = [
        "java",
        "--add-opens=java.base/jdk.internal.misc=ALL-UNNAMED",
        "-Dsbe.generate.stubs=false",
        "-Dsbe.generate.ir=true",
        "-Dsbe.output.dir=$(output_dir)",
    ]
    xinclude && push!(command_args, "-Dsbe.xinclude.aware=true")
    append!(command_args, [
        "-cp",
        jar_path,
        "uk.co.real_logic.sbe.SbeTool",
        schema_path,
    ])
    command = Cmd(command_args)
    accepted = success(pipeline(command; stdout=devnull, stderr=devnull))
    accepted || return false, nothing

    schema_name = splitext(basename(schema_path))[1]
    ir_path = joinpath(output_dir, "$(schema_name).sbeir")
    isfile(ir_path) || error("SbeTool accepted $(schema_path) but did not produce $(ir_path)")
    return true, SBE.decode_ir(ir_path)
end

function normalize_primitive_value(
    primitive_type::SBE.IR.PrimitiveType.T,
    value::Union{Nothing, String},
)
    value === nothing && return nothing
    if primitive_type == SBE.IR.PrimitiveType.CHAR
        all(isdigit, value) && return value
        ncodeunits(value) == 1 && return string(Int(codeunit(value, 1)))
    end
    return value
end

function normalize_character_encoding(
    primitive_type::SBE.IR.PrimitiveType.T,
    value::Union{Nothing, String},
)
    primitive_type == SBE.IR.PrimitiveType.CHAR && value === nothing && return "US-ASCII"
    return value
end

function token_signature(token::SBE.IR.Token)
    encoding = token.encoding
    return (
        token.signal,
        token.name,
        token.referenced_name,
        token.id,
        token.version,
        token.deprecated,
        token.encoded_length,
        token.offset,
        token.component_token_count,
        encoding.presence,
        encoding.primitive_type,
        encoding.byte_order,
        normalize_primitive_value(
            encoding.primitive_type,
            encoding.min_value === nothing ? nothing : encoding.min_value.value,
        ),
        normalize_primitive_value(
            encoding.primitive_type,
            encoding.max_value === nothing ? nothing : encoding.max_value.value,
        ),
        normalize_primitive_value(
            encoding.primitive_type,
            encoding.null_value === nothing ? nothing : encoding.null_value.value,
        ),
        normalize_primitive_value(
            encoding.primitive_type,
            encoding.const_value === nothing ? nothing : encoding.const_value.value,
        ),
        normalize_character_encoding(encoding.primitive_type, encoding.character_encoding),
        encoding.epoch,
        encoding.time_unit,
        encoding.semantic_type,
        token.description,
        token.package_name,
    )
end

token_signatures(tokens::Vector{SBE.IR.Token}) = map(token_signature, tokens)

function type_token_signatures(tokens::Vector{SBE.IR.Token})
    signatures = token_signatures(tokens)
    isempty(signatures) && return signatures

    # A captured type's outer offset is inherited from whichever message field
    # SbeTool encounters first. Its message map has unspecified iteration order,
    # so that occurrence-specific offset is not a stable property of the type.
    signatures[1] = Base.setindex(signatures[1], 0, 8)
    signatures[end] = Base.setindex(signatures[end], 0, 8)
    return signatures
end

function sorted_token_groups(groups; normalize_type_offsets::Bool=false)
    return sort!(
        [
            (
                name,
                normalize_type_offsets ? type_token_signatures(tokens) : token_signatures(tokens),
            ) for (name, tokens) in groups
        ];
        by=first,
    )
end

function ir_signature(ir::SBE.IR.Ir)
    return (
        ir.id,
        ir.version,
        ir.package_name,
        ir.namespace_name,
        ir.byte_order,
        ir.semantic_version,
        token_signatures(ir.header_structure.tokens),
        sorted_token_groups(ir.messages_by_id),
        sorted_token_groups(ir.types_by_name; normalize_type_offsets=true),
    )
end

function first_difference(actual, expected, path::AbstractString="IR")
    actual == expected && return nothing
    if actual isa Tuple && expected isa Tuple
        for index in eachindex(actual, expected)
            difference = first_difference(actual[index], expected[index], "$(path)[$(index)]")
            difference === nothing || return difference
        end
    elseif actual isa AbstractVector && expected isa AbstractVector
        length(actual) == length(expected) ||
            return "$(path) length: SBE.jl=$(length(actual)), SbeTool=$(length(expected))"
        for index in eachindex(actual, expected)
            difference = first_difference(actual[index], expected[index], "$(path)[$(index)]")
            difference === nothing || return difference
        end
    end
    return "$(path): SBE.jl=$(repr(actual)), SbeTool=$(repr(expected))"
end

function fixture_sync_errors(resources_dir::AbstractString, local_resources::AbstractString)
    errors = String[]
    for upstream_path in schema_files(resources_dir)
        relative_path = relpath(upstream_path, resources_dir)
        local_path = joinpath(local_resources, relative_path)
        if !isfile(local_path)
            push!(errors, "$(relative_path): missing vendored fixture")
        elseif read(local_path) != read(upstream_path)
            push!(errors, "$(relative_path): vendored fixture differs from upstream")
        end
    end
    return errors
end

function main(args::Vector{String}=ARGS)
    length(args) == 2 || error("expected upstream resources directory and sbe-all jar path")
    resources_dir, jar_path = args
    isdir(resources_dir) || error("resources directory not found: $(resources_dir)")
    isfile(jar_path) || error("SbeTool jar not found: $(jar_path)")

    files = schema_files(resources_dir)
    local_resources = normpath(joinpath(@__DIR__, "..", "test", "resources"))
    errors = fixture_sync_errors(resources_dir, local_resources)
    acceptance_mismatches = 0
    ir_mismatches = 0
    accepted_count = 0
    mktempdir() do output_dir
        for schema_path in files
            relative_path = relpath(schema_path, resources_dir)
            julia_accepted, julia_ir = sbejl_accepts(schema_path)
            java_accepted, java_ir = mktempdir(output_dir) do schema_output_dir
                sbetool_result(schema_path, jar_path, schema_output_dir)
            end
            if julia_accepted != java_accepted
                acceptance_mismatches += 1
                push!(
                    errors,
                    "$(relative_path): acceptance SBE.jl=$(julia_accepted), SbeTool=$(java_accepted)",
                )
            elseif julia_accepted
                accepted_count += 1
                difference = first_difference(ir_signature(julia_ir), ir_signature(java_ir))
                if difference !== nothing
                    ir_mismatches += 1
                    push!(errors, "$(relative_path): $(difference)")
                end
            end
        end

        xinclude_path = joinpath(resources_dir, "sub", "basic-schema.xml")
        julia_xinclude_ir = SBE.generate_ir_file(xinclude_path; suppress_warnings=true)
        java_xinclude_accepted, java_xinclude_ir = mktempdir(output_dir) do schema_output_dir
            sbetool_result(
                xinclude_path,
                jar_path,
                schema_output_dir;
                xinclude=true,
            )
        end
        if !java_xinclude_accepted
            acceptance_mismatches += 1
            push!(errors, "sub/basic-schema.xml: SbeTool rejected XInclude-aware parsing")
        else
            difference = first_difference(
                ir_signature(julia_xinclude_ir),
                ir_signature(java_xinclude_ir),
            )
            if difference !== nothing
                ir_mismatches += 1
                push!(errors, "sub/basic-schema.xml (XInclude): $(difference)")
            end
        end
    end

    for message in errors
        println(stderr, message)
    end
    isempty(errors) || error(
        "compatibility check failed: $(acceptance_mismatches) acceptance mismatch(es), " *
        "$(ir_mismatches) IR mismatch(es), $(length(errors)) total error(s)",
    )
    println(
        "SBE.jl and SbeTool agree on $(length(files)) fixture files, " *
        "schema acceptance, IR for $(accepted_count) accepted schemas, " *
        "and relative XInclude parsing",
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
