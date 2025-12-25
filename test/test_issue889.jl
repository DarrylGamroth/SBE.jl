using Test

@testset "Issue889 Optional Enum Null" begin
    buffer = zeros(UInt8, 32)
    header = Issue889.MessageHeader.Encoder(buffer, 0)
    enc = Issue889.EnumMessage.Encoder(buffer, 0; header=header)
    Issue889.EnumMessage.field1!(enc, Issue889.LotType.ROUND_LOT)

    dec = Issue889.EnumMessage.Decoder(buffer, 0)
    @test Issue889.EnumMessage.field1(dec) == Issue889.LotType.ROUND_LOT

    Issue889.EnumMessage.field1!(enc, Issue889.LotType.NULL_VALUE)
    dec_null = Issue889.EnumMessage.Decoder(buffer, 0)
    @test Issue889.EnumMessage.field1(dec_null) == Issue889.LotType.NULL_VALUE
end
