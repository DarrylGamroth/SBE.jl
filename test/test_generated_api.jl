using Test
using SBE

function generated_submodules(root::Module)
    modules = Module[root]
    for name in names(root; all=true, imported=false)
        isdefined(root, name) || continue
        value = getfield(root, name)
        value isa Module || continue
        value === root && continue
        parentmodule(value) === root || continue
        append!(modules, generated_submodules(value))
    end
    return modules
end

function generated_undocumented_names(mod::Module)
    if isdefined(Docs, :undocumented_names)
        return Docs.undocumented_names(mod; private=false)
    end

    undocumented = Symbol[]
    for name in names(mod; imported=false)
        name === nameof(mod) && continue
        binding = Docs.Binding(mod, name)
        haskey(Docs.meta(mod), binding) && continue

        # A module's docstring is stored in that module's metadata on Julia
        # 1.10, rather than on the exported binding in its parent module.
        if isdefined(mod, name)
            value = getfield(mod, name)
            if value isa Module
                module_binding = Docs.Binding(value, nameof(value))
                haskey(Docs.meta(value), module_binding) && continue
            end
        end
        push!(undocumented, name)
    end
    return undocumented
end

@testset "Generated Julia API" begin
    @testset "Convenience constructors" begin
        buffer = zeros(UInt8, 512)
        encoder = Baseline.Car.Encoder(buffer)

        @test encoder isa Baseline.Car.Encoder{Vector{UInt8}}
        @test SBE.sbe_offset(encoder) == 8
        @test SBE.sbe_description(encoder) == "Description of a basic Car"
        @test Baseline.Car.Decoder(buffer) isa Baseline.Car.Decoder{Vector{UInt8}}
    end

    @testset "Fluent fixed-field setters" begin
        buffer = zeros(UInt8, 512)
        encoder = Baseline.Car.Encoder(buffer)

        @test Baseline.Car.serialNumber!(encoder, 12345) === encoder
        @test Baseline.Car.modelYear!(encoder, 2024) === encoder
        @test Baseline.Car.available!(encoder, Baseline.BooleanType.T) === encoder
        @test Baseline.Car.code!(encoder, Baseline.Model.A) === encoder
        @test Baseline.Car.someNumbers!(encoder, (1, 2, 3, 4)) === encoder
        @test Baseline.Car.vehicleCode!(encoder, "ABC123") === encoder

        engine = Baseline.Car.engine(encoder)
        @test Baseline.Engine.capacity!(engine, 2000) === engine
        @test Baseline.Engine.numCylinders!(engine, 4) === engine
        @test Baseline.Engine.manufacturerCode!(engine, "XYZ") === engine

        extras = Baseline.Car.extras(encoder)
        Baseline.OptionalExtras.clear!(extras)
        @test Baseline.OptionalExtras.sunRoof!(extras, true) === extras

        decoder = Baseline.Car.Decoder(buffer)
        @test Baseline.Car.serialNumber(decoder) == 12345
        @test String(Baseline.Car.vehicleCode(decoder)) == "ABC123"
    end

    @testset "Character encoding validation" begin
        buffer = zeros(UInt8, 512)
        encoder = Baseline.Car.Encoder(buffer)

        @test_throws ArgumentError Baseline.Car.vehicleCode!(encoder, "ABCDEFG")
        @test_throws ArgumentError Baseline.Car.vehicleCode!(encoder, "é")
        @test_throws ArgumentError Baseline.Car.vehicleCode!(
            encoder,
            fill(UInt8('A'), 7),
        )

        Baseline.Car.fuelFigures!(encoder, 0)
        Baseline.Car.performanceFigures_group_count!(encoder, 0)
        @test_throws ArgumentError Baseline.Car.activationCode!(encoder, "é")
    end

    @testset "Groups and variable data" begin
        buffer = zeros(UInt8, 512)
        encoder = Baseline.Car.Encoder(buffer)

        @test Baseline.Car.fuelFigures!(encoder, 0) isa Baseline.Car.FuelFigures.Encoder
        @test Baseline.Car.performanceFigures_group_count!(encoder, 0) isa
              Baseline.Car.PerformanceFigures.Encoder
        @test Baseline.Car.manufacturer!(encoder, "日本") === encoder
        @test Baseline.Car.model!(encoder, "Civic") === encoder
        @test Baseline.Car.activationCode!(encoder, "ASCII") === encoder

        decoder = Baseline.Car.Decoder(buffer)
        foreach(_ -> nothing, Baseline.Car.fuelFigures(decoder))
        foreach(_ -> nothing, Baseline.Car.performanceFigures(decoder))
        @test Baseline.Car.manufacturer(decoder, String) == "日本"
        @test Baseline.Car.model(decoder, String) == "Civic"
        @test Baseline.Car.activationCode(decoder, String) == "ASCII"
    end

    @testset "Header mismatch diagnostics" begin
        error = try
            Baseline.Car.Decoder(zeros(UInt8, 64))
            nothing
        catch err
            err
        end

        @test error isa ArgumentError
        @test occursin("expected template/schema 1/1, got 0/0", error.msg)
    end

    @testset "Documentation and exports" begin
        for mod in generated_submodules(Baseline)
            @test isempty(generated_undocumented_names(mod))
        end

        manufacturer_doc = string(@doc Baseline.Car.manufacturer)
        @test occursin("UTF-8", manufacturer_doc)
        @test occursin("advances the shared message position", manufacturer_doc)
        @test :manufacturer in names(Baseline.Car)
        @test :manufacturer! in names(Baseline.Car)
    end
end
