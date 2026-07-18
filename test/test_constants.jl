using Test
using SBE

@testset "Constant Fields" begin
    @testset "Constant Field Values" begin
        # Create a properly encoded message
        buffer = zeros(UInt8, 2048)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
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
        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)
        
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
    
    @testset "Constant fields have no setters" begin
        @test !isdefined(Baseline.Engine, :maxRpm!)
        @test !isdefined(Baseline.Car, :discountedModel!)
    end
end
