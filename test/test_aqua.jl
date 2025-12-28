using Aqua
using Test
using SBE

@testset "Aqua" begin
    Aqua.test_all(
        SBE;
        ambiguities=false,
        unbound_args=false,
        piracies=false,
        persistent_tasks=false,
        stale_deps=false
    )
end
