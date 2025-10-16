using Test

@testset "SBE.jl Tests" begin
    # Core infrastructure tests
    include("test_metaprogramming.jl")
    include("test_schema_loader.jl")
    
    # Feature tests
    include("test_consistent_field_api.jl")
    include("test_vardata.jl")
    include("test_groups.jl")
    include("test_constants.jl")
    include("test_display.jl")
    include("test_version_handling.jl")
    include("test_version_all_types.jl")
    include("test_optional_fields.jl")
    
    # Complex patterns and edge cases (from sbe-tool test suite)
    include("test_complex_patterns.jl")
    
    # Performance regression tests
    include("test_allocations.jl")
end
