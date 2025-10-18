using Test

# Load pre-generated schemas for file-based testing
include("generated/Baseline.jl")
include("generated/Extension.jl")
include("generated/Optional.jl")
include("generated/Versioned.jl")
include("generated/OrderCheck.jl")

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
    include("test_nested_types_in_composites.jl")  # Nested enums and sets in composites
    include("test_optional_fields.jl")  # Optional field handling tests
    include("test_consistent_field_api.jl")  # Consistent API tests (Baseline schema)
    
    # Integration and validation tests
    include("test_complex_patterns.jl")
    include("test_allocations.jl")
    include("test_interop.jl")  # Binary compatibility with sbe-tool Java generator
end
