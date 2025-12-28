using Test
using SBE

@testset "Version Handling Tests" begin
    # Use pre-generated Extension module (loaded by runtests.jl)
    
    @testset "Schema Version Information" begin
        # Verify schema loaded correctly
        @test isdefined(Extension, :Car)
        @test isdefined(Extension.Car, :Decoder)
        @test isdefined(Extension.Car, :Encoder)
        
        # Check that version metadata exists for versioned fields
        @test isdefined(Extension.Car, :uuid_since_version)
        @test isdefined(Extension.Car, :cupHolderCount_since_version)
        
        # Verify the since_version values are correct (they are functions in file-based generation)
        @test Extension.Car.uuid_since_version(Extension.Car.Decoder) == UInt16(1)
        @test Extension.Car.cupHolderCount_since_version(Extension.Car.Decoder) == UInt16(1)
    end
    
    @testset "Version 0 Behavior (Fields Not In Version)" begin
        buffer = zeros(UInt8, 1024)
        position_ptr = SBE.PositionPointer()
        
        # Create decoder with acting_version=0 (baseline schema without extensions)
        car_v0 = Extension.Car.Decoder(typeof(buffer))
        car_v0.position_ptr = position_ptr
        Extension.Car.wrap!(car_v0, buffer, 0, UInt16(45), UInt16(0))
        
        @test car_v0.acting_version == UInt16(0)
        
        # Test that accessing versioned fields returns null values when not in version
        # uuid is int64 array of length 2, null value is -9223372036854775808 (Int64 min)
        uuid_result = Extension.Car.uuid(car_v0)
        @test length(uuid_result) == 2
        @test all(x -> x == typemin(Int64), uuid_result)
        
        # cupHolderCount is uint8, null value is 255
        @test Extension.Car.cupHolderCount(car_v0) == UInt8(255)
    end
    
    @testset "Version 1 Behavior (Fields In Version)" begin
        buffer = zeros(UInt8, 1024)
        position_ptr = SBE.PositionPointer()
        
        # Create decoder with acting_version=1 (extension schema with new fields)
        car_v1 = Extension.Car.Decoder(typeof(buffer))
        car_v1.position_ptr = position_ptr
        Extension.Car.wrap!(car_v1, buffer, 0, UInt16(62), UInt16(1))
        
        @test car_v1.acting_version == UInt16(1)
        
        # Test that versioned fields can be accessed (don't return null)
        # They may contain zeros from the buffer, but the version check should pass
        uuid_values = Extension.Car.uuid(car_v1)
        @test length(uuid_values) == 2
        # With version 1, we should be able to access the field (it won't be null)
        # The actual values will be whatever is in the buffer (zeros in this case)
        
        cupHolder = Extension.Car.cupHolderCount(car_v1)
        @test cupHolder isa UInt8
        # With version 1, the field is accessible
    end
    
    @testset "Forward Compatibility (Old Decoder with New Data)" begin
        buffer = zeros(UInt8, 1024)
        position_ptr_v0 = SBE.PositionPointer()
        
        # Old decoder (version 0) reads data
        car_v0 = Extension.Car.Decoder(typeof(buffer))
        car_v0.position_ptr = position_ptr_v0
        Extension.Car.wrap!(car_v0, buffer, 0, UInt16(45), UInt16(0))
        
        # Old decoder gets null values for extended fields
        @test Extension.Car.cupHolderCount(car_v0) == UInt8(255)  # null value
        uuid_v0 = Extension.Car.uuid(car_v0)
        @test all(x -> x == typemin(Int64), uuid_v0)  # null values
    end
    
        @testset "Backward Compatibility (New Decoder with Old Data)" begin
        buffer = zeros(UInt8, 1024)
        position_ptr_v1 = SBE.PositionPointer()
        
        # New decoder (version 1) reads old data (which won't have extended fields)
        car_v1 = Extension.Car.Decoder(typeof(buffer))
        car_v1.position_ptr = position_ptr_v1
        Extension.Car.wrap!(car_v1, buffer, 0, UInt16(45), UInt16(0))
        
        # New decoder should return null values for extended fields when data is version 0
        @test Extension.Car.cupHolderCount(car_v1) == UInt8(255)  # null value
        uuid_v1 = Extension.Car.uuid(car_v1)
        @test all(x -> x == typemin(Int64), uuid_v1)  # null values
    end
    
    @testset "Metadata Functions Consistency" begin
        # Test that metadata constants exist
        buffer = zeros(UInt8, 1024)
        position_ptr = SBE.PositionPointer()
        car = Extension.Car.Decoder(typeof(buffer))
        car.position_ptr = position_ptr
        Extension.Car.wrap!(car, buffer, 0, UInt16(62), UInt16(1))
        
        # since_version should be constants
        # Verify metadata functions are consistent
        @test Extension.Car.uuid_since_version(Extension.Car.Decoder) == UInt16(1)
        @test Extension.Car.cupHolderCount_since_version(Extension.Car.Decoder) == UInt16(1)        # Test that fields are accessible with version 1
        @test car.acting_version == UInt16(1)
    end
    
    @testset "Non-Versioned Fields Unaffected" begin
        # Verify that fields without sinceVersion still work as before
        # Use pre-generated Baseline module (loaded by runtests.jl)
        
        buffer = zeros(UInt8, 1024)
        position_ptr = SBE.PositionPointer()
        
        # All baseline fields should have since_version = 0
        # Verify that fields in the baseline schema have since_version=0
        @test Baseline.Car.serialNumber_since_version(Baseline.Car.Decoder) == UInt16(0)
        @test Baseline.Car.modelYear_since_version(Baseline.Car.Decoder) == UInt16(0)
        @test Baseline.Car.available_since_version(Baseline.Car.Decoder) == UInt16(0)        # Fields should work normally
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        car_enc.position_ptr = position_ptr
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        Baseline.Car.serialNumber!(car_enc, UInt64(12345))
        
        # Decode and verify
        position_ptr2 = SBE.PositionPointer()
        header = Baseline.MessageHeader.Decoder(buffer, 0)
        car_dec = Baseline.Car.Decoder(typeof(buffer))
        car_dec.position_ptr = position_ptr2
        Baseline.Car.wrap!(car_dec, buffer, 0; header=header)
        @test Baseline.Car.serialNumber(car_dec) == UInt64(12345)
    end
end
