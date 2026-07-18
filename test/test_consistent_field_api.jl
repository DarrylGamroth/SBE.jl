using Test
using SBE

@testset "Consistent Field API Tests" begin
    
    @testset "Composite Direct Accessor API" begin
        buffer = zeros(UInt8, 64)

        # Test Engine composite with new direct accessor API
        engine_decoder = Baseline.Engine.Decoder(buffer, 0)
        engine_encoder = Baseline.Engine.Encoder(buffer, 0)
        
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
        
    end
    
    @testset "Message Direct Accessor API" begin
        buffer = zeros(UInt8, 1024)
        
        # Create encoder and decoder with proper header
        header = Baseline.MessageHeader.Encoder(buffer, 0)
        car_encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_encoder, buffer, 0; header=header)
        car_decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(car_decoder, buffer, 0)
        
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
        
    end
    
    @testset "Field Metadata Information" begin
        buffer = zeros(UInt8, 64)
        
        # Create decoder instances to test metadata functions
        engine_decoder = Baseline.Engine.Decoder(buffer, 0)
        
        # Test composite field metadata (functions in file-based generation)
        @test Baseline.Engine.capacity_encoding_length(engine_decoder) == 2
        @test Baseline.Engine.capacity_encoding_offset(engine_decoder) == 0

        # Test message field metadata.
        @test Baseline.Car.modelYear_encoding_length(Baseline.Car.Decoder) == 2
        @test Baseline.Car.modelYear_encoding_offset(Baseline.Car.Decoder) == 8
        @test Baseline.Car.modelYear_id(Baseline.Car.Decoder) == UInt16(2)
    end
    
    @testset "Array Field Direct Accessors" begin
        buffer = zeros(UInt8, 1024)
        
        # Create encoder and decoder
        header = Baseline.MessageHeader.Encoder(buffer, 0)
        car_encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_encoder, buffer, 0; header=header)
        car_decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(car_decoder, buffer, 0)
        
        # Test SomeNumbers array field - write then read
        Baseline.Car.someNumbers!(car_encoder, [10, 20, 30, 40])
        some_numbers_value = Baseline.Car.someNumbers(car_decoder)
        
        @test some_numbers_value isa AbstractVector{UInt32}
        @test length(some_numbers_value) == 4
        @test collect(some_numbers_value) == UInt32[10, 20, 30, 40]
        
        # Test metadata (functions in file-based generation)
        @test Baseline.Car.someNumbers_encoding_length(Baseline.Car.Decoder) == 16
        @test Baseline.Car.someNumbers_encoding_offset(Baseline.Car.Decoder) == 12
    end
end
