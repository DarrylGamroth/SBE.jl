module SBE

# Load dependencies
using EnumX
import XML
using MappedArrays
using StringViews
using UnsafeArrays

"""
    PositionPointer

Mutable position tracker for SBE message decoding/encoding.
Used to track the current position in a buffer as variable-length
fields are processed.

# Examples
```julia
pos = PositionPointer()
pos[] = 100      # Set position
current = pos[]  # Get position
```
"""
mutable struct PositionPointer
    value::Int64
    PositionPointer() = new(0)
    PositionPointer(v::Integer) = new(Int64(v))
end

Base.getindex(pos::PositionPointer) = pos.value
Base.setindex!(pos::PositionPointer, v) = (pos.value = Int64(v))

# ============================================================================
# SBE Interface Function Declarations
# ============================================================================
# These are declared here BEFORE includes so all included files can use them.
# They are extended by generated types to provide type-specific implementations.

"""
Generic interface function for getting values from SBE fields.
This is extended by generated types to provide type-specific implementations.
"""
function value end

"""
Generic interface function for setting values in SBE fields.
This is extended by generated types to provide type-specific implementations.
"""
function value! end

"""
Generic interface function for getting meta-attributes from SBE fields.
This is extended by generated types to provide type-specific implementations.
"""
function meta_attribute end

"""
Return the SBE field ID for this field type.
"""
function id end

"""
Return the SBE version when this field was introduced.
"""
function since_version end

"""
Check if this field is present in the given acting version.
"""
function in_acting_version end

"""
Return the byte offset of this field within its parent message.
"""
function encoding_offset end

"""
Return the total number of bytes this field occupies.
"""
function encoding_length end

"""
Return the null/sentinel value for this field type.
"""
function null_value end

"""
Return the minimum valid value for this field type.
"""
function min_value end

"""
Return the maximum valid value for this field type.
"""
function max_value end

"""
Return the underlying buffer for this SBE object.
"""
function sbe_buffer end

"""
Return the byte offset of this SBE object in the buffer.
"""
function sbe_offset end

"""
Return the acting version of the schema being used.
"""
function sbe_acting_version end

"""
Return the encoded length of this message in bytes.
"""
function sbe_encoded_length end

"""
Return the SBE template ID for this message type.
"""
function sbe_template_id end

"""
Return the SBE schema ID.
"""
function sbe_schema_id end

"""
Return the SBE schema version.
"""
function sbe_schema_version end

"""
Return the block length for this message type.
"""
function sbe_block_length end

"""
Return the acting block length for this message instance.
"""
function sbe_acting_block_length end

"""
Return the position pointer for this message (shared with groups/var data).
"""
function sbe_position_ptr end

"""
Return the current position in the buffer.
"""
function sbe_position end

"""
Set the current position in the buffer.
"""
function sbe_position! end

"""
Rewind the position to the start of variable-length data section.
"""
function sbe_rewind! end

"""
Return the decoded length of this message (requires traversing groups/var data).
"""
function sbe_decoded_length end

"""
Return the semantic type hint for this field.
"""
function sbe_semantic_type end

"""
Return the description of this message type.
"""
function sbe_description end

# ============================================================================
# Include Source Files
# ============================================================================

# Intermediate Representation (IR)
include("IR.jl")
import .IR

# IR generation from XML
include("ir_generator.jl")

# IR decoding from .sbeir
include("ir_decoder.jl")
import .IrDecoder: decode_ir

# IR code generation utilities
include("ir_codegen.jl")

# Code generation utilities (includes abstract types and runtime support)
include("codegen_utils.jl")

# ============================================================================
# Expansion-time schema loading
# ============================================================================

"""
    @load_schema xml_path; module_name=nothing

Generate an SBE schema during macro expansion and emit its codec module as
ordinary top-level Julia syntax.

`xml_path` must be a string literal. Relative paths in source files are resolved
relative to the file containing the macro call; at the REPL they are resolved
relative to the working directory. The macro must be used at top level. The
generated module is installed in the calling module and its name is returned as
a `Symbol`.

Because the generated definitions are evaluated as a top-level form, functions
defined afterward see the codec methods in their world age and can call them
normally without `Base.invokelatest`.

# Arguments
- `xml_path`: Literal path to the SBE XML schema file
- `module_name`: Optional literal override for the generated module name

# Returns
The generated module name as a `Symbol`.

# Example
```julia
using SBE

# Load during expansion; paths are relative to this source file.
module_name = SBE.@load_schema "test/example-schema.xml"
# => :Baseline

# Access it in the calling module.
Baseline = getfield(@__MODULE__, module_name)

# Or use directly
buffer = zeros(UInt8, 1024)
car = Baseline.Car.Encoder(buffer, 0)
```

# Advantages
- Generated methods predate functions defined after the macro call
- Code is generated during expansion and evaluated as a top-level form
- Clean, simple syntax
- No temporary files
- Idempotent: calling multiple times with the same schema is safe (uses existing module)

# Notes
Generated modules cannot be redefined in a running Julia session. If the target name
already identifies a module when the macro is expanded, the macro reuses it. Use
[`generate`](@ref) when the schema path is only known at runtime; evaluate the
resulting file at top level or cross the dynamic-loading boundary with
`Base.invokelatest`.

# See Also
- `generate(xml_path)` - Generate code as string
"""
function _macro_literal_path(value, source::LineNumberNode, macro_name::String)
    value isa String || throw(ArgumentError(
        "$macro_name requires a string literal path; use the corresponding " *
        "generation function when the path is only known at runtime"
    ))
    isabspath(value) && return normpath(value)

    source_file = String(source.file)
    base_dir = source_file == "none" || isempty(source_file) ?
        pwd() : dirname(abspath(source_file))
    return normpath(joinpath(base_dir, value))
end

function _macro_literal_module_name(value, macro_name::String)
    value === :nothing && return nothing
    value isa String && return value
    value isa QuoteNode && value.value isa Symbol && return value.value
    throw(ArgumentError("$macro_name module_name must be a literal String, Symbol, or nothing"))
end

function _macro_literal_bool(value, macro_name::String, keyword::Symbol)
    value isa Bool && return value
    throw(ArgumentError("$macro_name $keyword must be a literal Bool"))
end

function _macro_module_name(package_name::String, override)
    if override === nothing || override == "" || override == Symbol("")
        return module_name_from_package(package_name)
    end
    return Symbol(sanitize_identifier(String(override)))
end

function _generated_module_expansion(
    caller::Module,
    module_name::Symbol,
    code::String,
    source_path::String
)
    Base.include_dependency(source_path)
    if isdefined(caller, module_name)
        getfield(caller, module_name) isa Module || error(
            "cannot load generated module $module_name: caller already defines a non-module binding"
        )
        return Expr(:toplevel, QuoteNode(module_name))
    end

    expansion = Meta.parseall(
        code;
        filename=source_path * ".generated.jl",
        lineno=1
    )
    expansion.head == :toplevel || error("generated code is not a top-level expression")
    push!(expansion.args, QuoteNode(module_name))
    return expansion
end

macro load_schema(args...)
    xml_path_expr = nothing
    module_name_expr = :nothing
    validate_expr = true
    warnings_fatal_expr = false
    suppress_warnings_expr = false

    for arg in args
        if arg isa Expr && arg.head == :parameters
            for kw in arg.args
                kw isa Expr && (kw.head == :(=) || kw.head == :kw) ||
                    error("Unsupported @load_schema argument: $kw")
                name, value = kw.args
                if name == :module_name || name == :module
                    module_name_expr = value
                elseif name == :validate
                    validate_expr = value
                elseif name == :warnings_fatal
                    warnings_fatal_expr = value
                elseif name == :suppress_warnings
                    suppress_warnings_expr = value
                else
                    error("Unsupported @load_schema keyword argument: $name")
                end
            end
        elseif xml_path_expr === nothing
            xml_path_expr = arg
        else
            error("@load_schema accepts exactly one XML path")
        end
    end

    xml_path_expr === nothing && error("@load_schema requires an XML path")
    xml_path = _macro_literal_path(xml_path_expr, __source__, "@load_schema")
    module_name_override = _macro_literal_module_name(module_name_expr, "@load_schema")
    validate = _macro_literal_bool(validate_expr, "@load_schema", :validate)
    warnings_fatal = _macro_literal_bool(
        warnings_fatal_expr,
        "@load_schema",
        :warnings_fatal
    )
    suppress_warnings = _macro_literal_bool(
        suppress_warnings_expr,
        "@load_schema",
        :suppress_warnings
    )

    schema = parse_xml_schema_file(
        xml_path;
        validate=validate,
        warnings_fatal=warnings_fatal,
        suppress_warnings=suppress_warnings
    )
    module_name = _macro_module_name(schema.package_name, module_name_override)
    ir = generate_ir(schema)
    code = generate_from_ir(ir; module_name=module_name)
    return esc(_generated_module_expansion(__module__, module_name, code, xml_path))
end

"""
    @load_sbeir ir_path; module_name=nothing

Decode a Java-compatible `.sbeir` file and generate Julia codecs during macro
expansion. The macro emits the codec module as top-level syntax. The path and
optional module name must be literals. Path resolution, caller-module placement,
top-level use, idempotence, and world-age behavior are the same as for
[`@load_schema`](@ref).
"""
macro load_sbeir(args...)
    ir_path_expr = nothing
    module_name_expr = :nothing

    for arg in args
        if arg isa Expr && arg.head == :parameters
            for kw in arg.args
                kw isa Expr && (kw.head == :(=) || kw.head == :kw) ||
                    error("Unsupported @load_sbeir argument: $kw")
                name, value = kw.args
                if name == :module_name || name == :module
                    module_name_expr = value
                else
                    error("Unsupported @load_sbeir keyword argument: $name")
                end
            end
        elseif ir_path_expr === nothing
            ir_path_expr = arg
        else
            error("@load_sbeir accepts exactly one IR path")
        end
    end

    ir_path_expr === nothing && error("@load_sbeir requires an IR path")
    ir_path = _macro_literal_path(ir_path_expr, __source__, "@load_sbeir")
    module_name_override = _macro_literal_module_name(module_name_expr, "@load_sbeir")
    ir = decode_ir(ir_path)
    module_name = _macro_module_name(ir.package_name, module_name_override)
    code = generate_from_ir(ir; module_name=module_name)
    return esc(_generated_module_expansion(__module__, module_name, code, ir_path))
end

# Backwards-compatible alias for schema parsing.
parse_sbe_schema(xml_content::AbstractString) = parse_xml_schema(xml_content)

# Re-export important types and functions that users need
export @load_schema, @load_sbeir, parse_xml_schema, parse_xml_schema_file, parse_sbe_schema
export generate, generate_from_ir, generate_ir, generate_ir_xml, generate_ir_file
export IR  # Stable IR module surface

# Export position pointer type
export PositionPointer

# Export abstract types for interface
export AbstractSbeMessage, AbstractSbeField, AbstractSbeGroup, AbstractSbeData
export AbstractSbeEncodedType, AbstractSbeCompositeType

# Export interface functions
export id, since_version, in_acting_version, encoding_offset, encoding_length
export null_value, min_value, max_value, value, value!, meta_attribute
export sbe_buffer, sbe_offset, sbe_acting_version, sbe_encoded_length
export sbe_template_id, sbe_schema_id, sbe_schema_version, sbe_block_length
export sbe_acting_block_length, sbe_position_ptr, sbe_position, sbe_position!
export sbe_rewind!, sbe_decoded_length, sbe_semantic_type, sbe_description

# Export utility functions
export to_string

export decode_ir

end # module SBE
