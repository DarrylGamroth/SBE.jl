using Test

@testset "NPE Small Header" begin
    buffer = zeros(UInt8, 64)
    header = NpeSmallHeader.MessageHeader.Encoder(buffer, 0)
    NpeSmallHeader.MessageHeader.schemaId!(header, UInt16(2001))
    NpeSmallHeader.MessageHeader.version!(header, UInt8(1))
    NpeSmallHeader.MessageHeader.templateId!(header, UInt8(0))
    NpeSmallHeader.MessageHeader.blockLength!(header, UInt8(0))
    NpeSmallHeader.MessageHeader.numGroups!(header, UInt8(0))
    NpeSmallHeader.MessageHeader.numVarDataFields!(header, UInt8(0))

    ping = NpeSmallHeader.Ping.Encoder(buffer, 0; header=header)
    dec = NpeSmallHeader.Ping.Decoder(buffer, 0)
    @test NpeSmallHeader.MessageHeader.schemaId(NpeSmallHeader.MessageHeader.Decoder(buffer, 0)) == UInt16(2001)
    @test SBE.sbe_template_id(dec) == UInt16(0)
end
