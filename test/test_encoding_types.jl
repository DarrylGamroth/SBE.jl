using Test

@testset "Encoding Types" begin
    buffer = zeros(UInt8, 128)
    header = EncodingTypes.MessageHeader.Encoder(buffer, 0)
    enc = EncodingTypes.Message1.Encoder(typeof(buffer))
    EncodingTypes.Message1.wrap_and_apply_header!(enc, buffer, 0; header=header)

    EncodingTypes.Message1.eC!(enc, EncodingTypes.EChar.ValueB)
    EncodingTypes.Message1.e8!(enc, EncodingTypes.EUInt8.Value10)

    s8 = EncodingTypes.Message1.s8(enc)
    EncodingTypes.SUInt8.Bit0!(s8, true)
    EncodingTypes.SUInt8.Bit6!(s8, true)

    s16 = EncodingTypes.Message1.s16(enc)
    EncodingTypes.SUInt16.Bit15!(s16, true)

    s32 = EncodingTypes.Message1.s32(enc)
    EncodingTypes.SUInt32.Bit0!(s32, true)
    EncodingTypes.SUInt32.Bit16!(s32, true)
    EncodingTypes.SUInt32.Bit26!(s32, true)

    s64 = EncodingTypes.Message1.s64(enc)
    EncodingTypes.SUInt64.Bit0!(s64, true)
    EncodingTypes.SUInt64.Bit16!(s64, true)
    EncodingTypes.SUInt64.Bit26!(s64, true)

    dec = EncodingTypes.Message1.Decoder(typeof(buffer))
    EncodingTypes.Message1.wrap!(dec, buffer, 0)
    @test EncodingTypes.Message1.eC(dec) == EncodingTypes.EChar.ValueB
    @test EncodingTypes.Message1.e8(dec) == EncodingTypes.EUInt8.Value10

    s8d = EncodingTypes.Message1.s8(dec)
    @test EncodingTypes.SUInt8.Bit0(s8d)
    @test EncodingTypes.SUInt8.Bit6(s8d)

    s16d = EncodingTypes.Message1.s16(dec)
    @test EncodingTypes.SUInt16.Bit15(s16d)

    s32d = EncodingTypes.Message1.s32(dec)
    @test EncodingTypes.SUInt32.Bit0(s32d)
    @test EncodingTypes.SUInt32.Bit16(s32d)
    @test EncodingTypes.SUInt32.Bit26(s32d)

    s64d = EncodingTypes.Message1.s64(dec)
    @test EncodingTypes.SUInt64.Bit0(s64d)
    @test EncodingTypes.SUInt64.Bit16(s64d)
    @test EncodingTypes.SUInt64.Bit26(s64d)
end
