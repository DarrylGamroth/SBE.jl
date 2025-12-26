using Test

# Ensure Java fixtures are available when Java is installed.
function ensure_java_fixtures!()
    java = Sys.which("java")
    java === nothing && return

    fixture_dir = joinpath(@__DIR__, "java-fixtures")
    class_dir = joinpath(fixture_dir, "classes")
    sbe_version = get(ENV, "SBE_VERSION", "1.36.2")
    jar_default = joinpath(homedir(), ".cache", "sbe", "sbe-all-$(sbe_version).jar")
    jar_path = get(ENV, "SBE_JAR_PATH", jar_default)
    if haskey(ENV, "SBE_JAR_PATH") && !isfile(jar_path)
        error("SBE_JAR_PATH is set but does not exist: $(jar_path)")
    end

    if !isfile(jar_path) || !isdir(class_dir)
        script_path = joinpath(@__DIR__, "..", "scripts", "generate_java_fixtures.jl")
        isfile(script_path) || error("Missing Java fixture generator: $script_path")
        run(`$(Base.julia_cmd()) --project=$(joinpath(@__DIR__, "..")) $script_path`)
    end
end

ensure_java_fixtures!()

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

module GeneratedSinceDeprecated
    include("generated/SinceDeprecated.jl")
end
const SinceDeprecated = GeneratedSinceDeprecated.SinceDeprecated

module GeneratedSinceVersionFilter
    include("generated/SinceVersionFilter.jl")
end
const SinceVersionFilter = GeneratedSinceVersionFilter.SinceDeprecated

module GeneratedDeprecatedMessage
    include("generated/DeprecatedMessage.jl")
end
const DeprecatedMessage = GeneratedDeprecatedMessage.SinceDeprecated

module GeneratedExplicitPackage
    include("generated/ExplicitPackage.jl")
end
const ExplicitPackage = GeneratedExplicitPackage.TestMessageSchema

module GeneratedNpeSmallHeader
    include("generated/NpeSmallHeader.jl")
end
const NpeSmallHeader = GeneratedNpeSmallHeader.NOTUSED

module GeneratedBigEndianBaseline
    include("generated/BigEndianBaseline.jl")
end
const BigEndianBaseline = GeneratedBigEndianBaseline.BaselineBigendian

module GeneratedJsonPrinterSchema
    include("generated/JsonPrinterSchema.jl")
end
const JsonPrinterSchema = GeneratedJsonPrinterSchema.Baseline

module GeneratedBasicTypes
    include("generated/BasicTypes.jl")
end
const BasicTypes = GeneratedBasicTypes.SBETests

module GeneratedBasicVariableLength
    include("generated/BasicVariableLength.jl")
end
const BasicVariableLength = GeneratedBasicVariableLength.SBETests

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

module GeneratedEncodingTypes
    include("generated/EncodingTypes.jl")
end
const EncodingTypes = GeneratedEncodingTypes.SBETests

module GeneratedGroupWithConstantFields
    include("generated/GroupWithConstantFields.jl")
end
const GroupWithConstantFields = GeneratedGroupWithConstantFields.Baseline

module GeneratedNestedCompositeName
    include("generated/NestedCompositeName.jl")
end
const NestedCompositeName = GeneratedNestedCompositeName.NestedCompositeName

module GeneratedIssue1007
    include("generated/Issue1007.jl")
end
const Issue1007 = GeneratedIssue1007.Issue1007

module GeneratedIssue560
    include("generated/Issue560.jl")
end
const Issue560 = GeneratedIssue560.Issue560

module GeneratedIssue567
    include("generated/Issue567.jl")
end
const Issue567 = GeneratedIssue567.Tests

module GeneratedIssue895
    include("generated/Issue895.jl")
end
const Issue895 = GeneratedIssue895.Issue895

module GeneratedIssue910
    include("generated/Issue910.jl")
end
const Issue910 = GeneratedIssue910.Issue910

module GeneratedIssue967
    include("generated/Issue967.jl")
end
const Issue967 = GeneratedIssue967.Issue967

module GeneratedIssue972
    include("generated/Issue972.jl")
end
const Issue972 = GeneratedIssue972.Issue972

module GeneratedIssue984
    include("generated/Issue984.jl")
end
const Issue984 = GeneratedIssue984.Issue984

module GeneratedIssue987
    include("generated/Issue987.jl")
end
const Issue987 = GeneratedIssue987.Issue987

module GeneratedIssue1028
    include("generated/Issue1028.jl")
end
const Issue1028 = GeneratedIssue1028.Issue1028

module GeneratedIssue1057
    include("generated/Issue1057.jl")
end
const Issue1057 = GeneratedIssue1057.Issue1057

module GeneratedIssue1066
    include("generated/Issue1066.jl")
end
const Issue1066 = GeneratedIssue1066.Issue1066

module GeneratedIssue483
    include("generated/Issue483.jl")
end
const Issue483 = GeneratedIssue483.Issue483

module GeneratedIssue435
    include("generated/Issue435.jl")
end
const Issue435 = GeneratedIssue435.Issue435

module GeneratedIssue496
    include("generated/Issue496.jl")
end
const Issue496 = GeneratedIssue496.Issue488

module GeneratedIssue488
    include("generated/Issue488.jl")
end
const Issue488Schema = GeneratedIssue488.Issue488

module GeneratedIssue472
    include("generated/Issue472.jl")
end
const Issue472 = GeneratedIssue472.Issue472

module GeneratedIssue661
    include("generated/Issue661.jl")
end
const Issue661 = GeneratedIssue661.Issue661

module GeneratedIssue827
    include("generated/Issue827.jl")
end
const Issue827 = GeneratedIssue827.Issue827

module GeneratedIssue847
    include("generated/Issue847.jl")
end
const Issue847 = GeneratedIssue847.Issue847

module GeneratedIssue848
    include("generated/Issue848.jl")
end
const Issue848 = GeneratedIssue848.Issue848

module GeneratedIssue849
    include("generated/Issue849.jl")
end
const Issue849 = GeneratedIssue849.Issue849

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
    include("test_ir_utils.jl")  # IR/codegen utility coverage
    include("test_codegen_smoke.jl")  # Code generation smoke tests

    # Integration and validation tests
    include("test_complex_patterns.jl")
    include("test_allocations.jl")
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
    include("test_encoding_types.jl")  # Encoding types parity tests
    include("test_group_with_constant_fields.jl")  # Group constants parity tests
    include("test_nested_composite_name.jl")  # Nested composite name parity tests
    include("test_issue1007.jl")  # Keyword enum value parity tests
    include("test_issue560.jl")  # Constant valueRef parity tests
    include("test_issue567.jl")  # Group count width parity tests
    include("test_issue895.jl")  # Optional float/double parity tests
    include("test_issue910.jl")  # Keyword yield parity tests
    include("test_issue967.jl")  # Optional composite parity tests
    include("test_issue972.jl")  # Optional composite sinceVersion parity tests
    include("test_issue984.jl")  # Group field sinceVersion parity tests
    include("test_issue987.jl")  # Composite offsets parity tests
    include("test_issue1028.jl")  # Set sinceVersion in composite parity tests
    include("test_issue1057.jl")  # Set + ref composite parity tests
    include("test_issue1066.jl")  # Optional field sinceVersion parity tests
    include("test_issue889.jl")  # Optional enum null value parity tests
    include("test_since_deprecated.jl")  # Since/deprecated version gating tests
    include("test_since_version_filter.jl")  # SinceVersion filter parity tests
    include("test_deprecated_message.jl")  # Deprecated message parity tests
    include("test_explicit_package.jl")  # Explicit package type references
    include("test_npe_small_header.jl")  # Small header layout test
    include("test_bigendian_schema.jl")  # Big endian schema tests
    include("test_json_printer_schema.jl")  # Json printer schema tests
    include("test_basic_types_schema.jl")  # Basic types schema tests
    include("test_basic_variable_length_schema.jl")  # Basic var-data schema tests
    include("test_issue483.jl")  # Required/optional/constant parity tests
    include("test_issue435.jl")  # Enum/set reference parity tests
    include("test_issue496.jl")  # Nested composite refs parity tests
    include("test_issue488.jl")  # Var-data length parity tests
    include("test_issue472.jl")  # Optional uint64 parity tests
    include("test_issue661.jl")  # SinceVersion set parity tests
    include("test_issue827.jl")  # Big-endian set parity tests
    include("test_issue847.jl")  # Composite refs in message header
    include("test_issue848.jl")  # Composite refs in message and message header
    include("test_issue849.jl")  # Deep composite refs in message header and body
    include("test_error_paths.jl")  # Error-path coverage
    include("test_error_handlers.jl")  # Error handler schema validations
    include("test_aqua.jl")  # QA checks
end
