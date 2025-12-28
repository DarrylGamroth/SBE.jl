using Test
using SBE

@testset "Variable-Length Data" begin
    # Use pre-generated Baseline module (loaded by runtests.jl)
    
    @testset "Basic String Read/Write" begin
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
        # Write variable-length data
        manufacturer_text = "Honda"
        model_text = "Civic Type R"
        activation_text = "ABCD1234"
        
        Baseline.Car.manufacturer!(encoder, manufacturer_text)
        Baseline.Car.model!(encoder, model_text)
        Baseline.Car.activationCode!(encoder, activation_text)
        
        # Create decoder from same buffer
        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)
        
        # Read back and verify
        @test Baseline.Car.manufacturer(decoder, String) == manufacturer_text
        @test Baseline.Car.model(decoder, String) == model_text
        @test Baseline.Car.activationCode(decoder, String) == activation_text
    end
    
    @testset "Length Accessors" begin
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
        text = "TestData"
        Baseline.Car.manufacturer!(encoder, text)
        
        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)
        @test Baseline.Car.manufacturer_length(decoder) == length(text)
    end
    
    @testset "Skip Functions" begin
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
        manufacturer_text = "Honda"
        model_text = "Civic"
        
        Baseline.Car.manufacturer!(encoder, manufacturer_text)
        Baseline.Car.model!(encoder, model_text)
        
        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)
        
        # Skip manufacturer
        skipped = Baseline.Car.skip_manufacturer!(decoder)
        @test skipped == length(manufacturer_text)
        
        # Next field should be model
        @test Baseline.Car.model_length(decoder) == length(model_text)
        @test Baseline.Car.model(decoder, String) == model_text
    end
    
    @testset "Position Management" begin
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
        text1 = "First"
        text2 = "Second"
        
        initial_pos = SBE.sbe_position(encoder)
        Baseline.Car.manufacturer!(encoder, text1)
        after_first = SBE.sbe_position(encoder)
        
        # Position should have advanced by header (4 bytes) + data length
        @test after_first == initial_pos + 4 + length(text1)
        
        Baseline.Car.model!(encoder, text2)
        after_second = SBE.sbe_position(encoder)
        
        @test after_second == after_first + 4 + length(text2)
    end
    
    @testset "Type Conversions - Bytes" begin
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
        # Write raw bytes
        data = UInt8[0x01, 0x02, 0x03, 0x04]
        Baseline.Car.manufacturer!(encoder, data)
        
        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)
        result = Baseline.Car.manufacturer(decoder)
        
        @test collect(result) == data
    end
    
    @testset "Type Conversions - Symbol" begin
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
        # Write symbol
        sym = :TestSymbol
        Baseline.Car.manufacturer!(encoder, sym)
        
        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)
        result = Baseline.Car.manufacturer(decoder, Symbol)
        
        @test result == sym
    end
    
    @testset "Empty Strings" begin
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
        Baseline.Car.manufacturer!(encoder, "")
        
        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)
        @test Baseline.Car.manufacturer_length(decoder) == 0
        @test Baseline.Car.manufacturer(decoder, String) == ""
    end
    
    @testset "Multiple Fields in Sequence" begin
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
        # Write all var data fields
        Baseline.Car.manufacturer!(encoder, "Toyota")
        Baseline.Car.model!(encoder, "Corolla")
        Baseline.Car.activationCode!(encoder, "XYZ789")
        
        # Read back in order
        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)
        @test Baseline.Car.manufacturer(decoder, String) == "Toyota"
        @test Baseline.Car.model(decoder, String) == "Corolla"
        @test Baseline.Car.activationCode(decoder, String) == "XYZ789"
    end
    
    @testset "Metadata Constants" begin
        # Verify metadata constants are generated
        @test isdefined(Baseline.Car, :manufacturer_id)
        @test isdefined(Baseline.Car, :manufacturer_since_version)
        @test isdefined(Baseline.Car, :manufacturer_header_length)
        
        # Header length should be 4 (UInt32 for length)
        @test Baseline.Car.manufacturer_header_length == 4
    end
end
