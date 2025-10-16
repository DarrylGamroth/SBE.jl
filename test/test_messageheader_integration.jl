using Test
using SBE

@testset "MessageHeader Integration Tests" begin
    # Load the schema and get the generated module
    baseline = SBE.load_schema(joinpath(@__DIR__, "example-schema.xml"))
    
    @test isdefined(baseline, :MessageHeaderDecoder)
    @test isdefined(baseline, :MessageHeaderEncoder)
    
    # Test creating MessageHeader instances
    buffer = zeros(UInt8, 64)
    
    # Create encoder and set values
    header_encoder = baseline.MessageHeaderEncoder(buffer, 0, 0)
    baseline.blockLength!(header_encoder, UInt16(16))
    baseline.templateId!(header_encoder, UInt16(1))
    baseline.schemaId!(header_encoder, UInt16(1))
    baseline.version!(header_encoder, UInt16(0))
    
    # Create decoder and read values back
    header_decoder = baseline.MessageHeaderDecoder(buffer, 0, 0)
    @test baseline.blockLength(header_decoder) == UInt16(16)
    @test baseline.templateId(header_decoder) == UInt16(1)
    @test baseline.schemaId(header_decoder) == UInt16(1)
    @test baseline.version(header_decoder) == UInt16(0)
    
    # Test size
    @test baseline.sbe_encoded_length(header_decoder) == 8
    @test sizeof(header_decoder) == 8
end
