using Test
using SBE
using SBE.Schema

@testset "Consistent Field API Tests" begin
    # Load the baseline schema for testing
    Baseline = load_schema(joinpath(@__DIR__, "example-schema.xml"))
    
    @testset "Composite Direct Accessor API" begin
        buffer = zeros(UInt8, 64)
        
        # Test Engine composite with new direct accessor API
        engine_decoder = Baseline.Engine.Decoder(buffer, 0)
        engine_encoder = Baseline.Engine.Encoder(buffer, 0)
        
        @test typeof(engine_decoder) <: SBE.AbstractSbeCompositeType
        @test typeof(engine_encoder) <: SBE.AbstractSbeCompositeType
        
        # Test direct field accessor (no intermediate field object)
        capacity_value = Baseline.Engine.capacity(engine_decoder)
        @test capacity_value isa UInt16
        @test capacity_value == 0  # zero-initialized buffer
        
        # Test setting values with encoder
        Baseline.Engine.capacity!(engine_encoder, UInt16(2000))
        @test Baseline.Engine.capacity(engine_decoder) == 2000
        
        # Test numCylinders field
        cylinders_value = Baseline.Engine.numCylinders(engine_decoder)
        @test cylinders_value isa UInt8
        
        Baseline.Engine.numCylinders!(engine_encoder, UInt8(6))
        @test Baseline.Engine.numCylinders(engine_decoder) == 6
        
        # Test metadata constants are available
        @test isdefined(Baseline.Engine, :capacity_encoding_offset)
        @test isdefined(Baseline.Engine, :capacity_encoding_length)
    end
    
    @testset "Message Direct Accessor API" begin
        buffer = zeros(UInt8, 1024)
        
        # Create encoder and decoder with proper header
        header = Baseline.MessageHeader.Encoder(buffer, 0)
        car_encoder = Baseline.Car.Encoder(buffer, 0, header=header)
        car_decoder = Baseline.Car.Decoder(buffer, 0)
        
        @test typeof(car_decoder) <: SBE.AbstractSbeMessage
        @test typeof(car_encoder) <: SBE.AbstractSbeMessage
        
        # Test direct field accessor - write with encoder, read with decoder
        Baseline.Car.modelYear!(car_encoder, UInt16(2024))
        model_year_value = Baseline.Car.modelYear(car_decoder)
        @test model_year_value isa UInt16
        @test model_year_value == 2024
        
        # Test vehicle code field (character array - returns String)
        Baseline.Car.vehicleCode!(car_encoder, b"ABC")
        vehicle_code_value = Baseline.Car.vehicleCode(car_decoder)
        @test vehicle_code_value isa AbstractString
        @test vehicle_code_value == "ABC"
        
        # Test metadata constants
        @test isdefined(Baseline.Car, :modelYear_encoding_offset)
        @test isdefined(Baseline.Car, :modelYear_encoding_length)
        @test isdefined(Baseline.Car, :modelYear_id)
        @test isdefined(Baseline.Car, :modelYear_since_version)
    end
    
    @testset "API Consistency Between Composite and Message" begin
        buffer = zeros(UInt8, 1024)
        
        # Set up both composite and message
        engine_decoder = Baseline.Engine.Decoder(buffer, 0)
        engine_encoder = Baseline.Engine.Encoder(buffer, 0)
        
        header = Baseline.MessageHeader.Encoder(buffer, 100)
        car_encoder = Baseline.Car.Encoder(buffer, 100, header=header)
        car_decoder = Baseline.Car.Decoder(buffer, 100)
        
        # Both should have direct accessor functions
        @test hasmethod(Baseline.Engine.capacity, Tuple{typeof(engine_decoder)})
        @test hasmethod(Baseline.Engine.capacity!, Tuple{typeof(engine_encoder), UInt16})
        
        @test hasmethod(Baseline.Car.modelYear, Tuple{typeof(car_decoder)})
        @test hasmethod(Baseline.Car.modelYear!, Tuple{typeof(car_encoder), UInt16})
        
        # Both types should be subtypes of appropriate abstracts
        @test typeof(engine_decoder) <: SBE.AbstractSbeCompositeType
        @test typeof(car_decoder) <: SBE.AbstractSbeMessage
        
        # Both should have SBE interface methods
        @test hasmethod(SBE.sbe_buffer, Tuple{typeof(engine_decoder)})
        @test hasmethod(SBE.sbe_buffer, Tuple{typeof(car_decoder)})
        
        @test hasmethod(SBE.sbe_offset, Tuple{typeof(engine_decoder)})
        @test hasmethod(SBE.sbe_offset, Tuple{typeof(car_decoder)})
    end
    
    @testset "Field Metadata Information" begin
        buffer = zeros(UInt8, 64)
        
        # Create decoder instances to test metadata functions
        engine_decoder = Baseline.Engine.Decoder(buffer, 0)
        
        # Test composite field metadata (functions, not constants)
        # Metadata functions take the decoder instance
        @test Baseline.Engine.capacity_encoding_length(engine_decoder) == 2  # sizeof(UInt16)
        @test Baseline.Engine.capacity_encoding_offset(engine_decoder) isa Int
        
        # Test message field metadata (static constants in new message API)
        @test Baseline.Car.modelYear_encoding_length == 2  # sizeof(UInt16)
        @test Baseline.Car.modelYear_encoding_offset isa Int
        @test Baseline.Car.modelYear_id isa UInt16
        @test Baseline.Car.modelYear_since_version isa UInt16
    end
    
    @testset "Array Field Direct Accessors" begin
        buffer = zeros(UInt8, 1024)
        
        # Create encoder and decoder
        header = Baseline.MessageHeader.Encoder(buffer, 0)
        car_encoder = Baseline.Car.Encoder(buffer, 0, header=header)
        car_decoder = Baseline.Car.Decoder(buffer, 0)
        
        # Test SomeNumbers array field - write then read
        Baseline.Car.someNumbers!(car_encoder, [10, 20, 30, 40])
        some_numbers_value = Baseline.Car.someNumbers(car_decoder)
        
        @test some_numbers_value isa AbstractVector{UInt32}
        @test length(some_numbers_value) == 4
        @test collect(some_numbers_value) == UInt32[10, 20, 30, 40]
        
        # Test metadata
        @test Baseline.Car.someNumbers_encoding_length == 16  # 4 * sizeof(UInt32)
        @test Baseline.Car.someNumbers_encoding_offset isa Int
    end
end
