using Test

# Load pre-generated schemas for file-based testing
include("generated/Baseline.jl")
include("generated/Extension.jl")
include("generated/Optional.jl")
include("generated/Versioned.jl")
include("generated/OrderCheck.jl")

@testset "SBE.jl Tests" begin
    # Tests migrated to file-based generation
    include("test_metaprogramming.jl")
    include("test_vardata.jl")
    include("test_groups.jl")
    include("test_constants.jl")
    include("test_display.jl")
    include("test_version_handling.jl")
    include("test_version_all_types.jl")
    include("test_complex_patterns.jl")
    include("test_allocations.jl")
    include("test_load_schema_macro.jl")  # Tests @load_schema macro functionality
    include("test_consistent_field_api.jl")  # Consistent API tests (Baseline schema)
    include("test_optional_fields.jl")  # Optional field handling tests
    include("test_interop.jl")  # Binary compatibility with sbe-tool Java generator
    
    # Note: test_schema_loader.jl removed - functionality covered by test_load_schema_macro.jl
end
