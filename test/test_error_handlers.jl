using Test
using SBE

@testset "Error Handler Schemas" begin
    base_dir = joinpath(@__DIR__, "resources")

    @test_throws ErrorException SBE.generate(joinpath(base_dir, "error-handler-group-dimensions-schema.xml"))
    @test_throws ErrorException SBE.generate(joinpath(base_dir, "error-handler-message-schema.xml"))
end
