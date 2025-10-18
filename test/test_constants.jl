using Test

# SBE should already be loaded by runtests.jl
# If running standalone, load it
if !isdefined(Main, :SBE)
    using Pkg
    Pkg.activate(joinpath(@__DIR__, ".."))
    using SBE
end

@testset "Constant Fields" begin
    # Use pre-generated Baseline module (loaded by runtests.jl)
    # Baseline should already be defined in Main scope

@testset "Constant Field Detection" begin
        # Test that constant fields exist in message and composites
        @test isdefined(Baseline.Car, :discountedModel)
        @test isdefined(Baseline.Engine, :maxRpm)
        @test isdefined(Baseline.Engine, :fuel)
    end
    
    @testset "Constant Field Values" begin
        # Create a properly encoded message
        buffer = zeros(UInt8, 2048)
        encoder = Baseline.Car.Encoder(buffer, 0)
        
        # Encode required fields
        Baseline.Car.serialNumber!(encoder, 12345)
        Baseline.Car.modelYear!(encoder, 2024)
        Baseline.Car.available!(encoder, Baseline.BooleanType.T)
        Baseline.Car.code!(encoder, Baseline.Model.A)
        Baseline.Car.someNumbers!(encoder, UInt32[1, 2, 3, 4])
        Baseline.Car.vehicleCode!(encoder, codeunits("ABCDEF"))
        
        # Engine fields
        engine = Baseline.Car.engine(encoder)
        Baseline.Engine.capacity!(engine, 2000)
        Baseline.Engine.numCylinders!(engine, 4)
        
        # Now decode and check constant values
        decoder = Baseline.Car.Decoder(buffer, 0)
        
        # Test discountedModel constant (should return Model.C)
        @test Baseline.Car.discountedModel(decoder) == Baseline.Model.C
        
        # Test engine constants
        engine_dec = Baseline.Car.engine(decoder)
        
        # maxRpm should return 9000 (constant value)
        @test Baseline.Engine.maxRpm(engine_dec) == UInt16(9000)
        
        # fuel should return "Petrol" (constant string)
        fuel_value = Baseline.Engine.fuel(engine_dec)
        @test fuel_value isa AbstractString
        @test fuel_value == "Petrol"
    end
    
    @testset "Constant Field Encoding Behavior" begin
        buffer = zeros(UInt8, 2048)
        encoder = Baseline.Car.Encoder(buffer, 0)
        
        # Encode required fields
        Baseline.Car.serialNumber!(encoder, 12345)
        Baseline.Car.modelYear!(encoder, 2024)
        Baseline.Car.available!(encoder, Baseline.BooleanType.T)
        Baseline.Car.code!(encoder, Baseline.Model.A)
        Baseline.Car.someNumbers!(encoder, UInt32[1, 2, 3, 4])
        Baseline.Car.vehicleCode!(encoder, codeunits("ABCDEF"))
        
        # Test that constant fields have setters (or don't, depending on implementation)
        engine = Baseline.Car.engine(encoder)
        
        # For constants, setters should NOT be generated
        # Check that setters don't exist
        @test !isdefined(Baseline.Engine, :maxRpm!)
        @test !isdefined(Baseline.Car, :discountedModel!)
        
        # For now, just verify that calling the getter returns the constant
        # regardless of what's in the buffer
    end
end
