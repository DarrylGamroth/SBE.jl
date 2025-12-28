using Test
using SBE

# Include the generated Baseline schema
include("generated/Baseline.jl")

@testset "Nested Types in Composites" begin
    @testset "Nested Enum in Composite - BoostType" begin
        # Test 1: Enum type exists
        @test isdefined(Baseline.Booster, :BoostType)
        
        # Test 2: Enum values are correct
        @test UInt8(Baseline.Booster.BoostType.TURBO) == UInt8('T')
        @test UInt8(Baseline.Booster.BoostType.SUPERCHARGER) == UInt8('S')
        @test UInt8(Baseline.Booster.BoostType.NITROUS) == UInt8('N')
        @test UInt8(Baseline.Booster.BoostType.KERS) == UInt8('K')
        @test UInt8(Baseline.Booster.BoostType.NULL_VALUE) == UInt8(0x00)
        
        # Test 3: Field accessor exists
        @test hasmethod(Baseline.Booster.boostType, (Baseline.Booster.Decoder,))
        @test hasmethod(Baseline.Booster.boostType!, (Baseline.Booster.Encoder, Any))
        
        # Test 4: Correct offset for boostType (should be 0)
        buffer = zeros(UInt8, 10)
        booster = Baseline.Booster.Decoder(buffer, 0, UInt16(0))
        @test Baseline.Booster.boostType_encoding_offset(booster) == 0
        @test Baseline.Booster.boostType_encoding_length(booster) == 1
        
        # Test 5: Correct offset for horsePower (should be 1, after the enum)
        @test Baseline.Booster.horsePower_encoding_offset(booster) == 1
        @test Baseline.Booster.horsePower_encoding_length(booster) == 1
        
        # Test 6: Composite size includes both fields
        @test Baseline.Booster.sbe_encoded_length(booster) == 2  # 1 byte enum + 1 byte horsePower
        
        # Test 7: Read/write boostType enum
        buffer = zeros(UInt8, 2)
        booster_enc = Baseline.Booster.Encoder(buffer, 0)
        
        # Write TURBO enum value
        Baseline.Booster.boostType!(booster_enc, Baseline.Booster.BoostType.TURBO)
        @test buffer[1] == UInt8('T')
        
        # Read back the enum value
        booster_dec = Baseline.Booster.Decoder(buffer, 0, UInt16(0))
        boost_type_val = Baseline.Booster.boostType(booster_dec)
        @test boost_type_val == Baseline.Booster.BoostType.TURBO
        
        # Test 8: Write different enum values
        Baseline.Booster.boostType!(booster_enc, Baseline.Booster.BoostType.SUPERCHARGER)
        @test buffer[1] == UInt8('S')
        @test Baseline.Booster.boostType(booster_dec) == Baseline.Booster.BoostType.SUPERCHARGER
        
        Baseline.Booster.boostType!(booster_enc, Baseline.Booster.BoostType.NITROUS)
        @test buffer[1] == UInt8('N')
        @test Baseline.Booster.boostType(booster_dec) == Baseline.Booster.BoostType.NITROUS
        
        Baseline.Booster.boostType!(booster_enc, Baseline.Booster.BoostType.KERS)
        @test buffer[1] == UInt8('K')
        @test Baseline.Booster.boostType(booster_dec) == Baseline.Booster.BoostType.KERS
    end
    
    @testset "Nested Enum + Primitive Field Offsets" begin
        # Test that horsePower is at the correct offset after the enum
        buffer = zeros(UInt8, 10)
        engine_enc = Baseline.Engine.Encoder(buffer, 0)
        booster_enc = Baseline.Booster.Encoder(buffer, 0)
        booster_dec = Baseline.Booster.Decoder(buffer, 0, UInt16(0))
        
        # Set boostType at offset 0
        Baseline.Booster.boostType!(booster_enc, Baseline.Booster.BoostType.TURBO)
        @test buffer[1] == UInt8('T')
        @test buffer[2] == 0  # horsePower not set yet
        
        # Set horsePower at offset 1
        Baseline.Booster.horsePower!(booster_enc, 250)
        @test buffer[1] == UInt8('T')  # boostType unchanged
        @test buffer[2] == 250         # horsePower at offset 1
        
        # Read both fields
        @test Baseline.Booster.boostType(booster_dec) == Baseline.Booster.BoostType.TURBO
        @test Baseline.Booster.horsePower(booster_dec) == 250
    end
    
    @testset "Nested Enum in Composite Used in Message" begin
        # Test that the nested enum works when the composite is used in a message
        buffer = zeros(UInt8, 1000)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        
        # Get the engine composite
        engine = Baseline.Car.engine(car_enc)
        
        # Get the booster composite from engine
        booster = Baseline.Engine.booster(engine)
        
        # Set boostType and horsePower
        Baseline.Booster.boostType!(booster, Baseline.Booster.BoostType.NITROUS)
        Baseline.Booster.horsePower!(booster, 200)
        
        # Decode and verify
        car_dec = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(car_dec, buffer, 0)
        engine_dec = Baseline.Car.engine(car_dec)
        booster_dec = Baseline.Engine.booster(engine_dec)
        
        @test Baseline.Booster.boostType(booster_dec) == Baseline.Booster.BoostType.NITROUS
        @test Baseline.Booster.horsePower(booster_dec) == 200
    end
    
    @testset "Nested Enum Metadata Functions" begin
        buffer = zeros(UInt8, 10)
        booster = Baseline.Booster.Decoder(buffer, 0, UInt16(0))
        
        # Test metadata accessors
        @test Baseline.Booster.boostType_id(booster) == 0xffff
        @test Baseline.Booster.boostType_id(Baseline.Booster.Decoder) == 0xffff
        @test Baseline.Booster.boostType_since_version(booster) == 0
        @test Baseline.Booster.boostType_since_version(Baseline.Booster.Decoder) == 0
        @test Baseline.Booster.boostType_in_acting_version(booster) == true
        @test Baseline.Booster.boostType_encoding_offset(booster) == 0
        @test Baseline.Booster.boostType_encoding_offset(Baseline.Booster.Decoder) == 0
        @test Baseline.Booster.boostType_encoding_length(booster) == 1
        @test Baseline.Booster.boostType_encoding_length(Baseline.Booster.Decoder) == 1
    end
end
