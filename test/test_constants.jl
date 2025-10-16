using Test

# SBE should already be loaded by runtests.jl
# If running standalone, load it
if !isdefined(Main, :SBE)
    using Pkg
    Pkg.activate(joinpath(@__DIR__, ".."))
    using SBE
end

@testset "Constant Fields" begin
    # Generate schema from XML
    TestSchema = SBE.load_schema(joinpath(@__DIR__, "example-schema.xml"))

@testset "Constant Field Detection" begin
        # Test that constant fields exist in message and composites
        @test isdefined(TestSchema.Car, :discountedModel)
        @test isdefined(TestSchema.Engine, :maxRpm)
        @test isdefined(TestSchema.Engine, :fuel)
    end
    
    @testset "Constant Field Values" begin
        # Create a properly encoded message
        buffer = zeros(UInt8, 2048)
        encoder = TestSchema.Car.Encoder(buffer, 0)
        
        # Encode required fields
        TestSchema.Car.serialNumber!(encoder, 12345)
        TestSchema.Car.modelYear!(encoder, 2024)
        TestSchema.Car.available!(encoder, TestSchema.BooleanType.T)
        TestSchema.Car.code!(encoder, TestSchema.Model.A)
        TestSchema.Car.someNumbers!(encoder, UInt32[1, 2, 3, 4])
        TestSchema.Car.vehicleCode!(encoder, codeunits("ABCDEF"))
        
        # Engine fields
        engine = TestSchema.Car.engine(encoder)
        TestSchema.Engine.capacity!(engine, 2000)
        TestSchema.Engine.numCylinders!(engine, 4)
        
        # Now decode and check constant values
        decoder = TestSchema.Car.Decoder(buffer, 0)
        
        # Test discountedModel constant (should return Model.C)
        @test TestSchema.Car.discountedModel(decoder) == TestSchema.Model.C
        
        # Test engine constants
        engine_dec = TestSchema.Car.engine(decoder)
        
        # maxRpm should return 9000 (constant value)
        @test TestSchema.Engine.maxRpm(engine_dec) == UInt16(9000)
        
        # fuel should return "Petrol" (constant string)
        fuel_value = TestSchema.Engine.fuel(engine_dec)
        @test fuel_value isa AbstractArray{UInt8}
        @test String(fuel_value) == "Petrol"
    end
    
    @testset "Constant Field Encoding Behavior" begin
        buffer = zeros(UInt8, 2048)
        encoder = TestSchema.Car.Encoder(buffer, 0)
        
        # Encode required fields
        TestSchema.Car.serialNumber!(encoder, 12345)
        TestSchema.Car.modelYear!(encoder, 2024)
        TestSchema.Car.available!(encoder, TestSchema.BooleanType.T)
        TestSchema.Car.code!(encoder, TestSchema.Model.A)
        TestSchema.Car.someNumbers!(encoder, UInt32[1, 2, 3, 4])
        TestSchema.Car.vehicleCode!(encoder, codeunits("ABCDEF"))
        
        # Test that constant fields have setters (or don't, depending on implementation)
        engine = TestSchema.Car.engine(encoder)
        
        # For constants, setters should NOT be generated
        # Check that setters don't exist
        @test !isdefined(TestSchema.Engine, :maxRpm!)
        @test !isdefined(TestSchema.Car, :discountedModel!)
        
        # For now, just verify that calling the getter returns the constant
        # regardless of what's in the buffer
    end
end
