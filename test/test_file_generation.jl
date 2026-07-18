using Test
using SBE

const BASELINE_SCHEMA_PATH = joinpath(@__DIR__, "example-schema.xml")

function include_generated_source(source::AbstractString, module_name::Symbol)
    host = Module(gensym(:GeneratedSourceHost))
    Base.include_string(host, source, "generated-$module_name.jl")
    return host, Base.invokelatest(getfield, host, module_name)
end

@testset "File-Based Generation" begin
    @testset "String output" begin
        source = SBE.generate(BASELINE_SCHEMA_PATH)

        @test !isempty(source)
        @test occursin("module Baseline", source)
        @test Meta.parseall(source) isa Expr
    end

    @testset "File output" begin
        mktempdir() do dir
            output_path = joinpath(dir, "nested", "Baseline.jl")
            result = SBE.generate(BASELINE_SCHEMA_PATH, output_path)

            @test result == output_path
            @test isfile(output_path)
            @test filesize(output_path) > 0
            @test Meta.parseall(read(output_path, String)) isa Expr

            host = Module(gensym(:GeneratedFileHost))
            Base.include(host, output_path)
            @test Base.invokelatest(isdefined, host, :Baseline)
        end
    end

    @testset "Generated codec smoke test" begin
        host, schema = include_generated_source(
            SBE.generate(BASELINE_SCHEMA_PATH),
            :Baseline,
        )
        @test schema isa Module

        decoded = Core.eval(host, quote
            buffer = zeros(UInt8, 512)
            encoder = Baseline.Car.Encoder(buffer)
            Baseline.Car.serialNumber!(encoder, UInt64(12345))
            decoder = Baseline.Car.Decoder(buffer)
            Baseline.Car.serialNumber(decoder)
        end)
        @test decoded == UInt64(12345)
    end
end
