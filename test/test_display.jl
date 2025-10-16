using Test

# SBE should already be loaded by runtests.jl
# If running standalone, load it
if !isdefined(Main, :SBE)
    using Pkg
    Pkg.activate(joinpath(@__DIR__, ".."))
    using SBE
end

@testset "Display Methods" begin
    # Generate schema from XML
    TestSchema = SBE.load_schema(joinpath(@__DIR__, "example-schema.xml"))
    
    @testset "Message Display" begin
        buffer = zeros(UInt8, 2048)
        encoder = TestSchema.Car.Encoder(buffer, 0)
        decoder = TestSchema.Car.Decoder(buffer, 0)
        
        # Test encoder display
        encoder_str = repr(encoder)
        @test contains(encoder_str, "Car.Encoder")
        @test contains(encoder_str, "template_id=1")
        @test contains(encoder_str, "schema_id=1")
        @test contains(encoder_str, "version=0")
        
        # Test decoder display
        decoder_str = repr(decoder)
        @test contains(decoder_str, "Car.Decoder")
        @test contains(decoder_str, "template_id=1")
        @test contains(decoder_str, "schema_id=1")
        @test contains(decoder_str, "version=0")
    end
    
    @testset "Composite Display" begin
        buffer = zeros(UInt8, 2048)
        encoder = TestSchema.Car.Encoder(buffer, 0)
        
        # Get engine composite
        engine = TestSchema.Car.engine(encoder)
        engine_str = repr(engine)
        
        @test contains(engine_str, "Engine")
        @test contains(engine_str, "offset=")
        @test contains(engine_str, "size=")
    end
    
    @testset "Enum Display" begin
        # Enums already display nicely thanks to EnumX
        model_a = TestSchema.Model.A
        model_str = repr(model_a)
        @test contains(model_str, "A")
    end
end
