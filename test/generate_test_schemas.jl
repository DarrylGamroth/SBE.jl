"""
Generate the Julia codecs used by the test suite into a temporary directory.

Generation is deliberately fail-fast: a missing schema, generation exception, or
empty output is a test setup failure. The returned dictionary maps fixture names
to absolute generated-source paths.
"""

using SBE

const TEST_SCHEMA_DIR = @__DIR__

test_fixture_module_name(fixture_name::Symbol) = Symbol("TestFixture", fixture_name)

# List of schemas to generate
const TEST_SCHEMAS = [
    ("example-schema.xml", "Baseline.jl", "Baseline"),
    ("example-extension-schema.xml", "Extension.jl", "Extension"),
    ("example-optional-schema.xml", "Optional.jl", "Optional"),
    ("example-versioned-schema.xml", "Versioned.jl", "Versioned"),
    (joinpath("resources", "java-json-printer-test-schema.xml"), "JsonPrinterBaseline.jl", "JsonPrinterBaseline"),
    (joinpath("resources", "java-code-generation-schema.xml"), "CodeGenerationTest.jl", "CodeGenerationTest"),
    (joinpath("resources", "field-order-check-schema.xml"), "OrderCheck.jl", "OrderCheck"),
    (
        joinpath("resources", "field-order-check-schema.xml"),
        "OrderCheckChecked.jl",
        "OrderCheckChecked",
        true,
    ),
    (joinpath("resources", "composite-elements-schema.xml"), "CompositeElements.jl", "CompositeElements"),
    (joinpath("resources", "issue505.xml"), "Issue505.jl", "Issue505"),
    (joinpath("resources", "issue560.xml"), "Issue560.jl", "Issue560"),
    (joinpath("resources", "issue567-valid.xml"), "Issue567.jl", "Issue567"),
    (joinpath("resources", "issue895.xml"), "Issue895.jl", "Issue895"),
    (joinpath("resources", "issue910.xml"), "Issue910.jl", "Issue910"),
    (joinpath("resources", "issue967.xml"), "Issue967.jl", "Issue967"),
    (joinpath("resources", "issue972.xml"), "Issue972.jl", "Issue972"),
    (joinpath("resources", "issue984.xml"), "Issue984.jl", "Issue984"),
    (joinpath("resources", "issue987.xml"), "Issue987.jl", "Issue987"),
    (joinpath("resources", "issue1028.xml"), "Issue1028.jl", "Issue1028"),
    (joinpath("resources", "issue1057.xml"), "Issue1057.jl", "Issue1057"),
    (joinpath("resources", "issue1066.xml"), "Issue1066.jl", "Issue1066"),
    (joinpath("resources", "issue889.xml"), "Issue889.jl", "Issue889"),
    (joinpath("resources", "since-deprecated-test-schema.xml"), "SinceDeprecated.jl", "SinceDeprecated"),
    (joinpath("resources", "since-version-filter-schema.xml"), "SinceVersionFilter.jl", "SinceVersionFilter"),
    (joinpath("resources", "deprecated-msg-test-schema.xml"), "DeprecatedMessage.jl", "DeprecatedMessage"),
    (joinpath("resources", "explicit-package-test-schema.xml"), "ExplicitPackage.jl", "ExplicitPackage"),
    (joinpath("resources", "npe-small-header.xml"), "NpeSmallHeader.jl", "NpeSmallHeader"),
    (joinpath("resources", "example-bigendian-test-schema.xml"), "BigEndianBaseline.jl", "BigEndianBaseline"),
    (joinpath("resources", "json-printer-test-schema.xml"), "JsonPrinterSchema.jl", "JsonPrinterSchema"),
    (joinpath("resources", "basic-types-schema.xml"), "BasicTypes.jl", "BasicTypes"),
    (joinpath("resources", "basic-variable-length-schema.xml"), "BasicVariableLength.jl", "BasicVariableLength"),
    (joinpath("resources", "value-ref-with-lower-case-enum.xml"), "ValueRefLowerCaseEnum.jl", "ValueRefLowerCaseEnum"),
    (joinpath("resources", "extension-schema.xml"), "ExtensionSchema.jl", "ExtensionSchema"),
    (joinpath("resources", "constant-enum-fields.xml"), "ConstantEnumFields.jl", "ConstantEnumFields"),
    (joinpath("resources", "value-ref-schema.xml"), "ValueRefSchema.jl", "ValueRefSchema"),
    (joinpath("resources", "group-with-data-schema.xml"), "GroupWithData.jl", "GroupWithData"),
    (joinpath("resources", "message-block-length-test.xml"), "MessageBlockLengthTest.jl", "MessageBlockLengthTest"),
    (joinpath("resources", "composite-offsets-schema.xml"), "CompositeOffsets.jl", "CompositeOffsets"),
    (joinpath("resources", "embedded-length-and-count-schema.xml"), "EmbeddedLengthAndCount.jl", "EmbeddedLengthAndCount"),
    (joinpath("resources", "message-with-lower-case-bitset.xml"), "LowerCaseBitset.jl", "LowerCaseBitset"),
    (joinpath("resources", "fixed-sized-primitive-array-types.xml"), "FixedSizedPrimitiveArray.jl", "FixedSizedPrimitiveArray"),
    (joinpath("resources", "encoding-types-schema.xml"), "EncodingTypes.jl", "EncodingTypes"),
    (joinpath("resources", "group-with-constant-fields.xml"), "GroupWithConstantFields.jl", "GroupWithConstantFields"),
    (joinpath("resources", "nested-composite-name.xml"), "NestedCompositeName.jl", "NestedCompositeName"),
    (joinpath("resources", "issue1007.xml"), "Issue1007.jl", "Issue1007"),
    (joinpath("resources", "issue483.xml"), "Issue483.jl", "Issue483"),
    (joinpath("resources", "issue435.xml"), "Issue435.jl", "Issue435"),
    (joinpath("resources", "issue496.xml"), "Issue496.jl", "Issue496"),
    (joinpath("resources", "issue488.xml"), "Issue488.jl", "Issue488"),
    (joinpath("resources", "issue472.xml"), "Issue472.jl", "Issue472"),
    (joinpath("resources", "issue661.xml"), "Issue661.jl", "Issue661"),
    (joinpath("resources", "issue827.xml"), "Issue827.jl", "Issue827"),
    (joinpath("resources", "issue847.xml"), "Issue847.jl", "Issue847"),
    (joinpath("resources", "issue848.xml"), "Issue848.jl", "Issue848"),
    (joinpath("resources", "issue849.xml"), "Issue849.jl", "Issue849"),
]

function generate_test_schemas(
    output_dir::AbstractString=mktempdir(; prefix="sbe-jl-tests-");
    verbose::Bool=false,
)
    mkpath(output_dir)
    generated = Dict{Symbol, String}()

    for fixture in TEST_SCHEMAS
        schema_file, output_file, fixture_name = fixture[1:3]
        precedence_checks = length(fixture) == 4 ? fixture[4] : false
        schema_path = joinpath(TEST_SCHEMA_DIR, schema_file)
        output_path = joinpath(output_dir, output_file)

        isfile(schema_path) || error("Test schema not found: $schema_path")
        verbose && println("Generating $fixture_name from $schema_file")

        result = SBE.generate(
            schema_path,
            output_path;
            module_name=test_fixture_module_name(Symbol(fixture_name)),
            suppress_warnings=true,
            precedence_checks=precedence_checks,
        )
        result == output_path || error(
            "Unexpected output path for $fixture_name: expected $output_path, got $result",
        )
        isfile(output_path) || error("Generated file not created: $output_path")
        filesize(output_path) > 0 || error("Generated file is empty: $output_path")

        generated[Symbol(fixture_name)] = output_path
    end

    return generated
end

if abspath(PROGRAM_FILE) == @__FILE__
    output_dir = if isempty(ARGS)
        mktempdir(; prefix="sbe-jl-tests-", cleanup=false)
    else
        abspath(only(ARGS))
    end
    generate_test_schemas(output_dir; verbose=true)
    println("Generated test codecs in: $output_dir")
end
