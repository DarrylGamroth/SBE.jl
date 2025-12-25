"""
Pre-generate all test schemas using SBE.generate()

This script generates Julia code from all SBE XML schemas used in the test suite.
Run this whenever schemas change or before running tests.

Usage:
    julia --project=. test/generate_test_schemas.jl
"""

using SBE

# Test directory
test_dir = @__DIR__
generated_dir = joinpath(test_dir, "generated")

# Ensure generated directory exists
mkpath(generated_dir)

println("Generating test schemas...")
println("=" ^ 70)

# List of schemas to generate
schemas = [
    ("example-schema.xml", "Baseline.jl", "Baseline"),
    ("example-extension-schema.xml", "Extension.jl", "Extension"),
    ("example-optional-schema.xml", "Optional.jl", "Optional"),
    ("example-versioned-schema.xml", "Versioned.jl", "Versioned"),
    (joinpath("resources", "java-json-printer-test-schema.xml"), "JsonPrinterBaseline.jl", "JsonPrinterBaseline"),
    (joinpath("resources", "java-code-generation-schema.xml"), "CodeGenerationTest.jl", "CodeGenerationTest"),
    (joinpath("resources", "field-order-check-schema.xml"), "OrderCheck.jl", "OrderCheck"),
    (joinpath("resources", "composite-elements-schema.xml"), "CompositeElements.jl", "CompositeElements"),
    (joinpath("resources", "issue505.xml"), "Issue505.jl", "Issue505"),
    (joinpath("resources", "issue560.xml"), "Issue560.jl", "Issue560"),
    (joinpath("resources", "issue567-valid.xml"), "Issue567.jl", "Issue567"),
    (joinpath("resources", "issue889.xml"), "Issue889.jl", "Issue889"),
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

for (schema_file, output_file, module_name) in schemas
    schema_path = joinpath(test_dir, schema_file)
    output_path = joinpath(generated_dir, output_file)
    
    if !isfile(schema_path)
        @warn "Schema not found: $schema_path"
        continue
    end
    
    try
        println("Generating $module_name...")
        println("  Schema: $schema_file")
        println("  Output: generated/$output_file")
        
        SBE.generate(schema_path, output_path)
        
        # Verify the file was created and has content
        if isfile(output_path)
            size_kb = filesize(output_path) / 1024
            println("  ✓ Generated successfully ($(round(size_kb, digits=1)) KB)")
        else
            @error "  ✗ Failed to create file"
        end
        
    catch e
        @error "Failed to generate $module_name" exception=(e, catch_backtrace())
    end
    println()
end

println("=" ^ 70)
println("Generation complete!")
println()
println("Generated files are in: $generated_dir")
println("Include them in tests with: include(\"generated/Baseline.jl\")")
