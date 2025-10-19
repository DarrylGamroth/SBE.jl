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
    (joinpath("resources", "field-order-check-schema.xml"), "OrderCheck.jl", "OrderCheck"),
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
