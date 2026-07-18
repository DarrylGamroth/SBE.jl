using Aqua
using Test
using SBE

@testset "Aqua" begin
    Aqua.test_all(SBE)
end

@testset "Aqua Generated Modules" begin
    Aqua.test_unbound_args(Baseline)
end
