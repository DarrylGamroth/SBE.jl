using Test

# Generate schemas for file-based testing
include("generate_test_schemas.jl")

# Load generated schemas for file-based testing
module GeneratedBaseline
    include("generated/Baseline.jl")
end
const Baseline = GeneratedBaseline.Baseline

module GeneratedExtension
    include("generated/Extension.jl")
end
const Extension = GeneratedExtension.Extension

module GeneratedOptional
    include("generated/Optional.jl")
end
const Optional = GeneratedOptional.Optional

module GeneratedVersioned
    include("generated/Versioned.jl")
end
const Versioned = GeneratedVersioned.Versioned

module GeneratedCodeGenerationTest
    include("generated/CodeGenerationTest.jl")
end
const CodeGenerationTest = GeneratedCodeGenerationTest.CodeGenerationTest

module GeneratedOrderCheck
    include("generated/OrderCheck.jl")
end
const OrderCheck = GeneratedOrderCheck.OrderCheck
const Order_check = OrderCheck

module GeneratedCompositeElements
    include("generated/CompositeElements.jl")
end
const CompositeElements = GeneratedCompositeElements.CompositeElements

module GeneratedIssue505
    include("generated/Issue505.jl")
end
const Issue505 = GeneratedIssue505.Issue505

module GeneratedIssue889
    include("generated/Issue889.jl")
end
const Issue889 = GeneratedIssue889.Issue889

module GeneratedValueRefLowerCaseEnum
    include("generated/ValueRefLowerCaseEnum.jl")
end
const ValueRefLowerCaseEnum = GeneratedValueRefLowerCaseEnum.Issue505

module GeneratedJsonPrinterBaseline
    include("generated/JsonPrinterBaseline.jl")
end
const JsonPrinterBaseline = GeneratedJsonPrinterBaseline.Baseline

module GeneratedExtensionSchema
    include("generated/ExtensionSchema.jl")
end
const ExtensionSchema = GeneratedExtensionSchema.CodeGenerationTest

module GeneratedConstantEnumFields
    include("generated/ConstantEnumFields.jl")
end
const ConstantEnumFields = GeneratedConstantEnumFields.Baseline

module GeneratedValueRefSchema
    include("generated/ValueRefSchema.jl")
end
const ValueRefSchema = GeneratedValueRefSchema.CompositeElements

module GeneratedGroupWithData
    include("generated/GroupWithData.jl")
end
const GroupWithData = GeneratedGroupWithData.GroupWithData

module GeneratedMessageBlockLengthTest
    include("generated/MessageBlockLengthTest.jl")
end
const MessageBlockLengthTest = GeneratedMessageBlockLengthTest.MessageBlockLengthTest

module GeneratedCompositeOffsets
    include("generated/CompositeOffsets.jl")
end
const CompositeOffsets = GeneratedCompositeOffsets.CompositeOffsetsTest

module GeneratedEmbeddedLengthAndCount
    include("generated/EmbeddedLengthAndCount.jl")
end
const EmbeddedLengthAndCount = GeneratedEmbeddedLengthAndCount.SBETests

module GeneratedLowerCaseBitset
    include("generated/LowerCaseBitset.jl")
end
const LowerCaseBitset = GeneratedLowerCaseBitset.Test973

module GeneratedFixedSizedPrimitiveArray
    include("generated/FixedSizedPrimitiveArray.jl")
end
const FixedSizedPrimitiveArray = GeneratedFixedSizedPrimitiveArray.FixedSizedPrimitiveArray

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
    include("test_composite_offsets.jl")  # Composite offset parity tests
    include("test_embedded_length_and_count.jl")  # Embedded length/count parity tests
    include("test_lower_case_bitset.jl")  # Lower-case bitset parity tests
    include("test_fixed_sized_primitive_array.jl")  # Fixed sized primitive array parity tests
end
