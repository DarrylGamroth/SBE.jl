#!/usr/bin/env julia
"""
Test IR-based code generation: XML → Schema → IR → Schema → Julia
"""

println("Loading modules...")

# Load necessary modules
module TestIRCodegen

include("src/Schema.jl")
using .Schema

include("src/IR.jl")
using .IR

# Mock utility functions
function to_julia_type(primitive_type::String)
    mapping = Dict(
        "char" => UInt8, "int8" => Int8, "int16" => Int16, "int32" => Int32, "int64" => Int64,
        "uint8" => UInt8, "uint16" => UInt16, "uint32" => UInt32, "uint64" => UInt64,
        "float" => Float32, "double" => Float64
    )
    get(mapping, lowercase(primitive_type), UInt8)
end

function get_field_size(schema::Schema.MessageSchema, field::Schema.FieldDefinition)
    for t in schema.types
        if (t isa Schema.EncodedType || t isa Schema.CompositeType || 
            t isa Schema.EnumType || t isa Schema.SetType) && 
            hasfield(typeof(t), :name) && getfield(t, :name) == field.type_ref
            if t isa Schema.EncodedType
                julia_type = to_julia_type(t.primitive_type)
                return sizeof(julia_type) * t.length
            end
        end
    end
    return 8
end

function calculate_composite_size(composite_def::Schema.CompositeType, schema::Schema.MessageSchema)
    total_size = 0
    for member in composite_def.members
        if member isa Schema.EncodedType && member.presence != "constant"
            julia_type = to_julia_type(member.primitive_type)
            total_size += sizeof(julia_type) * member.length
        end
    end
    return total_size
end

# Load schema_to_ir
include("src/schema_to_ir.jl")

# Load IR code generator
include("src/ir_codegen.jl")

end # module

println("✓ Modules loaded")

# Create a test schema
println("\nCreating test schema...")
test_schema = TestIRCodegen.Schema.MessageSchema(
    UInt16(1), UInt16(0), "", "test", "littleEndian", "messageHeader", "Test",
    TestIRCodegen.Schema.AbstractTypeDefinition[
        TestIRCodegen.Schema.EncodedType(
            "uint32", "uint32", 1, nothing, nothing, nothing,
            nothing, nothing, "required", nothing, nothing, "", 0, nothing
        )
    ],
    TestIRCodegen.Schema.MessageDefinition[
        TestIRCodegen.Schema.MessageDefinition(
            "TestMessage", UInt16(1), "4", "Test", 0, nothing, nothing,
            TestIRCodegen.Schema.FieldDefinition[
                TestIRCodegen.Schema.FieldDefinition(
                    "testField", UInt16(1), "uint32", 0, "", 0,
                    "required", nothing, "unix", nothing, nothing, nothing
                )
            ],
            TestIRCodegen.Schema.GroupDefinition[],
            TestIRCodegen.Schema.VarDataDefinition[]
        )
    ]
)

println("✓ Test schema created")

# Convert to IR
println("\nConverting Schema → IR...")
ir = TestIRCodegen.schema_to_ir(test_schema)
println("✓ IR generated (", length(ir.tokens), " tokens)")

# Convert IR back to Schema
println("\nConverting IR → Schema...")
schema_from_ir = TestIRCodegen.ir_to_schema(ir)
println("✓ Schema reconstructed from IR")

# Verify reconstruction
println("\nValidating roundtrip:")
println("  Original package: ", test_schema.package)
println("  Reconstructed package: ", schema_from_ir.package)
println("  Original messages: ", length(test_schema.messages))
println("  Reconstructed messages: ", length(schema_from_ir.messages))

if schema_from_ir.package == test_schema.package && 
   length(schema_from_ir.messages) == length(test_schema.messages)
    println("✓ IR roundtrip successful!")
else
    println("✗ IR roundtrip failed")
    exit(1)
end

println("\n✓ All tests passed!")
