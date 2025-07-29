using Test

@testset "SBE.jl Tests" begin
    include("test_metaprogramming.jl")
    include("test_schema_loader.jl")
end
