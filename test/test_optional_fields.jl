using Test
using SBE
using AllocCheck: check_allocs

# Load pre-generated Optional schema
include("generated/Optional.jl")

@testset "Optional Fields" begin
    
    @testset "Null Value Constants" begin
        # Test that null_value functions are generated for optional fields
        # In file-based generation, these are functions not constants
        @test Optional.Order.optionalPrice_null_value() == typemax(UInt32)
        @test Optional.Order.optionalVolume_null_value() == typemin(Int64)
        @test isnan(Optional.Order.optionalDiscount_null_value())
        
        # Optional enum should have null value
        @test Optional.Order.status_null_value() == typemax(UInt8)
    end
    
    @testset "Type Stability - Primitive Optional Fields" begin
        buffer = zeros(UInt8, 256)
        
        # Create encoder with header (encodes header automatically)
        header = Optional.MessageHeader.Encoder(buffer, 0)
        enc = Optional.Order.Encoder(buffer, 0; header=header)
        
        # Create decoder (reads header at offset 0 and validates it)
        msg = Optional.Order.Decoder(buffer, 0)
        
        # Accessors should return concrete types, NOT Union{T, Nothing}
        @test typeof(Optional.Order.optionalPrice(msg)) === UInt32
        @test typeof(Optional.Order.optionalVolume(msg)) === Int64
        @test typeof(Optional.Order.optionalDiscount(msg)) === Float32
        
        # Type stability check using @inferred
        @test (@inferred Optional.Order.optionalPrice(msg)) isa UInt32
        @test (@inferred Optional.Order.optionalVolume(msg)) isa Int64
        @test (@inferred Optional.Order.optionalDiscount(msg)) isa Float32
    end
    
    @testset "Type Stability - Optional Enum" begin
        buffer = zeros(UInt8, 256)
        
        # Create encoder with header
        header = Optional.MessageHeader.Encoder(buffer, 0)
        enc = Optional.Order.Encoder(buffer, 0, header=header)
        
        # Create decoder (starts after 8-byte message header)
        msg = Optional.Order.Decoder(buffer, 0)
        
        # Enum accessor should return concrete enum type
        status_val = Optional.Order.status(msg)
        @test typeof(status_val) === Optional.Status.SbeEnum
        
        # Should be type stable
        @test (@inferred Optional.Order.status(msg)) isa Optional.Status.SbeEnum
    end
    
    @testset "Encoding and Decoding Optional Fields - Non-null Values" begin
        buffer = zeros(UInt8, 256)
        
        # Create encoder with header and set values
        header = Optional.MessageHeader.Encoder(buffer, 0)
        enc = Optional.Order.Encoder(buffer, 0, header=header)
        Optional.Order.orderId!(enc, UInt64(12345))
        Optional.Order.quantity!(enc, UInt32(100))
        Optional.Order.optionalPrice!(enc, UInt32(9999))
        Optional.Order.optionalVolume!(enc, Int64(-500))
        Optional.Order.optionalDiscount!(enc, Float32(0.15))
        Optional.Order.status!(enc, Optional.Status.ACTIVE)
        Optional.Order.timestamp!(enc, UInt64(1234567890))
        
        # Decode and verify (starts after 8-byte message header)
        dec = Optional.Order.Decoder(buffer, 0)
        @test Optional.Order.orderId(dec) == UInt64(12345)
        @test Optional.Order.quantity(dec) == UInt32(100)
        @test Optional.Order.optionalPrice(dec) == UInt32(9999)
        @test Optional.Order.optionalVolume(dec) == Int64(-500)
        @test Optional.Order.optionalDiscount(dec) == Float32(0.15)
        @test Optional.Order.status(dec) == Optional.Status.ACTIVE
        @test Optional.Order.timestamp(dec) == UInt64(1234567890)
    end
    
    @testset "Encoding and Decoding Optional Fields - Null Values" begin
        buffer = zeros(UInt8, 256)
        
        # Create encoder with header and set null values explicitly
        header = Optional.MessageHeader.Encoder(buffer, 0)
        enc = Optional.Order.Encoder(buffer, 0, header=header)
        Optional.Order.orderId!(enc, UInt64(999))
        Optional.Order.quantity!(enc, UInt32(50))
        
        # Set optional fields to null values
        Optional.Order.optionalPrice!(enc, Optional.Order.optionalPrice_null_value())
        Optional.Order.optionalVolume!(enc, Optional.Order.optionalVolume_null_value())
        Optional.Order.optionalDiscount!(enc, Optional.Order.optionalDiscount_null_value())
        Optional.Order.status!(enc, Optional.Status.SbeEnum(Optional.Order.status_null_value()))
        
        Optional.Order.timestamp!(enc, UInt64(9999))
        
        # Decode and verify null values are preserved (starts after 8-byte message header)
        dec = Optional.Order.Decoder(buffer, 0)
        @test Optional.Order.orderId(dec) == UInt64(999)
        @test Optional.Order.quantity(dec) == UInt32(50)
        
        # Optional fields should return their null values
        @test Optional.Order.optionalPrice(dec) == typemax(UInt32)
        @test Optional.Order.optionalVolume(dec) == typemin(Int64)
        @test isnan(Optional.Order.optionalDiscount(dec))
        @test UInt8(Optional.Order.status(dec)) == typemax(UInt8)
        
        @test Optional.Order.timestamp(dec) == UInt64(9999)
    end
    
    @testset "Null Value Detection" begin
        buffer = zeros(UInt8, 256)
        
        # Encode with null values
        header = Optional.MessageHeader.Encoder(buffer, 0)
        enc = Optional.Order.Encoder(buffer, 0, header=header)
        Optional.Order.orderId!(enc, UInt64(1))
        Optional.Order.quantity!(enc, UInt32(1))
        Optional.Order.optionalPrice!(enc, Optional.Order.optionalPrice_null_value())
        Optional.Order.optionalVolume!(enc, Int64(500))  # Non-null
        Optional.Order.optionalDiscount!(enc, Optional.Order.optionalDiscount_null_value())
        Optional.Order.timestamp!(enc, UInt64(1))
        
        # Decode and check which fields are null (starts after 8-byte message header)
        dec = Optional.Order.Decoder(buffer, 0)
        
        # User can check for null by comparing to null_value()
        @test Optional.Order.optionalPrice(dec) == Optional.Order.optionalPrice_null_value()
        @test Optional.Order.optionalVolume(dec) != Optional.Order.optionalVolume_null_value()
        @test isnan(Optional.Order.optionalDiscount(dec)) && isnan(Optional.Order.optionalDiscount_null_value())
    end
    
    @testset "Round-trip Test with Mixed Null/Non-null" begin
        buffer1 = zeros(UInt8, 256)
        buffer2 = zeros(UInt8, 256)
        
        # Encode mixed null/non-null values
        header1 = Optional.MessageHeader.Encoder(buffer1, 0)
        enc = Optional.Order.Encoder(buffer1, 0; header=header1)
        Optional.Order.orderId!(enc, UInt64(777))
        Optional.Order.quantity!(enc, UInt32(25))
        Optional.Order.optionalPrice!(enc, UInt32(1234))  # Non-null
        Optional.Order.optionalVolume!(enc, Optional.Order.optionalVolume_null_value())  # Null
        Optional.Order.optionalDiscount!(enc, Float32(0.05))  # Non-null
        Optional.Order.status!(enc, Optional.Status.SbeEnum(Optional.Order.status_null_value()))  # Null
        Optional.Order.timestamp!(enc, UInt64(555))
        
        # Decode and re-encode (decoder reads header at offset 0)
        dec1 = Optional.Order.Decoder(buffer1, 0)
        header2 = Optional.MessageHeader.Encoder(buffer2, 0)
        enc2 = Optional.Order.Encoder(buffer2, 0; header=header2)
        
        Optional.Order.orderId!(enc2, Optional.Order.orderId(dec1))
        Optional.Order.quantity!(enc2, Optional.Order.quantity(dec1))
        Optional.Order.optionalPrice!(enc2, Optional.Order.optionalPrice(dec1))
        Optional.Order.optionalVolume!(enc2, Optional.Order.optionalVolume(dec1))
        Optional.Order.optionalDiscount!(enc2, Optional.Order.optionalDiscount(dec1))
        Optional.Order.status!(enc2, Optional.Order.status(dec1))
        Optional.Order.timestamp!(enc2, Optional.Order.timestamp(dec1))
        
        # Verify buffers are identical (compare only the block length portion)
        @test buffer1[1:50] == buffer2[1:50]
        
        # Verify decoded values (decoder reads header at offset 0)
        dec2 = Optional.Order.Decoder(buffer2, 0)
        @test Optional.Order.orderId(dec2) == UInt64(777)
        @test Optional.Order.optionalPrice(dec2) == UInt32(1234)
        @test Optional.Order.optionalVolume(dec2) == Optional.Order.optionalVolume_null_value()
        @test Optional.Order.optionalDiscount(dec2) == Float32(0.05)
        @test UInt8(Optional.Order.status(dec2)) == Optional.Order.status_null_value()
    end
    
    @testset "Zero-allocation Field Access" begin
        buffer = zeros(UInt8, 256)
        header = Optional.MessageHeader.Encoder(buffer, 0)
        enc = Optional.Order.Encoder(buffer, 0; header=header)
        Optional.Order.optionalPrice!(enc, UInt32(5000))
        
        dec = Optional.Order.Decoder(buffer, 0)
        
        # Accessing optional fields should not allocate
        @test isempty(check_allocs(Optional.Order.optionalPrice, (typeof(dec),)))
        @test isempty(check_allocs(Optional.Order.optionalVolume, (typeof(dec),)))
        @test isempty(check_allocs(Optional.Order.optionalDiscount, (typeof(dec),)))
    end
end
