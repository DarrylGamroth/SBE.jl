#!/usr/bin/env julia
"""
Basic IR generation test without full package dependencies.
This loads only what's needed to test IR generation.
"""

println("Loading modules...")

# Load core dependencies that we know are available
module TestIR

# Include the necessary modules in order
include("src/Schema.jl")
using .Schema

include("src/IR.jl") 
using .IR

# Mock the functions from codegen_utils that schema_to_ir needs
function to_julia_type(primitive_type::String)
    mapping = Dict(
        "char" => UInt8,
        "int8" => Int8,
        "int16" => Int16,
        "int32" => Int32,
        "int64" => Int64,
        "uint8" => UInt8,
        "uint16" => UInt16,
        "uint32" => UInt32,
        "uint64" => UInt64,
        "float" => Float32,
        "double" => Float64
    )
    get(mapping, lowercase(primitive_type), UInt8)
end

function get_field_size(schema::Schema.MessageSchema, field::Schema.FieldDefinition)
    # Simple implementation for testing
    type_def = nothing
    for t in schema.types
        if (t isa Schema.EncodedType || t isa Schema.CompositeType || 
            t isa Schema.EnumType || t isa Schema.SetType) && 
            hasfield(typeof(t), :name) && getfield(t, :name) == field.type_ref
            type_def = t
            break
        end
    end
    
    if type_def === nothing
        return 8  # default size
    end
    
    if type_def isa Schema.EncodedType
        julia_type = to_julia_type(type_def.primitive_type)
        return sizeof(julia_type) * type_def.length
    end
    
    return 8  # default
end

function calculate_composite_size(composite_def::Schema.CompositeType, schema::Schema.MessageSchema)
    total_size = 0
    for member in composite_def.members
        if member isa Schema.EncodedType
            if member.presence == "constant"
                continue
            end
            julia_type = to_julia_type(member.primitive_type)
            total_size += sizeof(julia_type) * member.length
        end
    end
    return total_size
end

# Now include schema_to_ir
include("src/schema_to_ir.jl")

end # module TestIR

println("✓ Modules loaded")

# Create a simple test schema
println("\nCreating test schema...")
test_schema = TestIR.Schema.MessageSchema(
    UInt16(1),  # id
    UInt16(0),  # version
    "",         # semantic_version
    "test",     # package
    "littleEndian",  # byte_order
    "messageHeader", # header_type
    "Test schema",   # description
    TestIR.Schema.AbstractTypeDefinition[
        TestIR.Schema.EncodedType(
            "uint32", "uint32", 1, nothing, nothing, nothing,
            nothing, nothing, "required", nothing, nothing, "", 0, nothing
        )
    ],  # types
    TestIR.Schema.MessageDefinition[
        TestIR.Schema.MessageDefinition(
            "TestMessage",  # name
            UInt16(1),      # id
            "4",            # block_length
            "Test message", # description
            0,              # since_version
            nothing,        # semantic_type
            nothing,        # deprecated
            TestIR.Schema.FieldDefinition[
                TestIR.Schema.FieldDefinition(
                    "testField",  # name
                    UInt16(1),    # id
                    "uint32",     # type_ref
                    0,            # offset
                    "Test field", # description
                    0,            # since_version
                    "required",   # presence
                    nothing,      # value_ref
                    "unix",       # epoch
                    nothing,      # time_unit
                    nothing,      # semantic_type
                    nothing       # deprecated
                )
            ],  # fields
            TestIR.Schema.GroupDefinition[],      # groups
            TestIR.Schema.VarDataDefinition[]     # var_data
        )
    ]  # messages
)

println("✓ Test schema created")

# Convert to IR
println("\nConverting to IR...")
ir = TestIR.schema_to_ir(test_schema)

println("✓ IR generated")
println("\nIR Frame:")
println("  Package: ", ir.frame.package_name)
println("  Schema ID: ", ir.frame.ir_id)
println("  Schema Version: ", ir.frame.schema_version)

println("\nIR Tokens (", length(ir.tokens), " total):")
for (i, token) in enumerate(ir.tokens)
    println("  $i: ", token.signal, " - ", token.name)
end

# Verify structure
message_begins = filter(t -> t.signal == TestIR.IR.BEGIN_MESSAGE, ir.tokens)
message_ends = filter(t -> t.signal == TestIR.IR.END_MESSAGE, ir.tokens)

println("\nValidation:")
println("  Messages: ", length(message_begins), " BEGIN, ", length(message_ends), " END")

if length(message_begins) == length(message_ends) && length(message_begins) == 1
    println("✓ All tests passed!")
else
    println("✗ Test failed: Token count mismatch")
    exit(1)
end
