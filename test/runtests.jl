using Test

# Generate schemas for file-based testing
include("generate_test_schemas.jl")

# Load generated schemas for file-based testing
include("generated/Baseline.jl")
include("generated/Extension.jl")
include("generated/Optional.jl")
include("generated/Versioned.jl")
include("generated/CodeGenerationTest.jl")
include("generated/OrderCheck.jl")
include("generated/CompositeElements.jl")
include("generated/Issue505.jl")
include("generated/Issue889.jl")
include("generated/ValueRefLowerCaseEnum.jl")
include("generated/ExtensionSchema.jl")
include("generated/ConstantEnumFields.jl")
include("generated/ValueRefSchema.jl")
include("generated/GroupWithData.jl")
include("generated/MessageBlockLengthTest.jl")

@testset "SBE.jl Tests" begin
    # Core functionality tests
    include("test_metaprogramming.jl")
    include("test_file_generation.jl")  # Tests generate() function
    include("test_load_schema_macro.jl")  # Tests @load_schema macro functionality
    
    # Feature tests
    include("test_vardata.jl")
    include("test_groups.jl")
    include("test_constants.jl")
    include("test_display.jl")
    include("test_version_handling.jl")
    include("test_version_all_types.jl")
    include("test_nested_types_in_composites.jl")  # Nested enums in composites
    include("test_nested_sets_in_composites.jl")  # Nested sets in composites
    include("test_optional_fields.jl")  # Optional field handling tests
    include("test_consistent_field_api.jl")  # Consistent API tests (Baseline schema)
    include("test_ir_decoder.jl")  # IR decoding vs sbeir

    # Integration and validation tests
    include("test_complex_patterns.jl")
    include("test_allocations.jl")
    include("test_interop.jl")  # Binary compatibility with sbe-tool Java generator
    include("test_java_fixtures.jl")  # Java-generator binary fixtures
    include("test_java_mirror.jl")  # Mirror Java generator tests
    include("test_java_generation_parity.jl")  # Java generator schema parity
    include("test_fixed_size_blob.jl")  # Fixed-length blob parity tests
    include("test_constant_enum_fields.jl")  # Constant enum field parity tests
    include("test_value_ref_schema.jl")  # ValueRef schema parity tests
    include("test_group_with_data.jl")  # Group-with-data parity tests
    include("test_message_block_length.jl")  # Block length parity tests
end
