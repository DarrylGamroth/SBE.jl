using Test

@testset "Issue889 Optional Enum Null" begin
    buffer = zeros(UInt8, 32)
    header = Issue889.MessageHeader.Encoder(buffer, 0)
    enc = Issue889.EnumMessage.Encoder(typeof(buffer))
    Issue889.EnumMessage.wrap_and_apply_header!(enc, buffer, 0; header=header)
    Issue889.EnumMessage.field1!(enc, Issue889.LotType.ROUND_LOT)

    dec = Issue889.EnumMessage.Decoder(typeof(buffer))
    Issue889.EnumMessage.wrap!(dec, buffer, 0)
    @test Issue889.EnumMessage.field1(dec) == Issue889.LotType.ROUND_LOT

    Issue889.EnumMessage.field1!(enc, Issue889.LotType.NULL_VALUE)
    dec_null = Issue889.EnumMessage.Decoder(typeof(buffer))
    Issue889.EnumMessage.wrap!(dec_null, buffer, 0)
    @test Issue889.EnumMessage.field1(dec_null) == Issue889.LotType.NULL_VALUE
end
