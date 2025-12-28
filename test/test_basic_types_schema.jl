using Test

@testset "Basic Types Schema" begin
    buffer = zeros(UInt8, 256)
    header = BasicTypes.MessageHeader.Encoder(buffer, 0)
    enc = BasicTypes.Message1.Encoder(typeof(buffer))
    BasicTypes.Message1.wrap_and_apply_header!(enc, buffer, 0; header=header)

    msg_header = BasicTypes.Message1.header(enc)
    BasicTypes.MessageHeader.blockLength!(msg_header, UInt16(128))
    BasicTypes.MessageHeader.templateId!(msg_header, UInt16(1))
    BasicTypes.MessageHeader.schemaId!(msg_header, UInt16(3))
    BasicTypes.MessageHeader.version!(msg_header, UInt16(1))

    BasicTypes.Message1.eDTField!(enc, "HELLO")
    BasicTypes.Message1.eNUMField!(enc, BasicTypes.ENUM.Value10)
    set_enc = BasicTypes.Message1.sETField(enc)
    BasicTypes.SET.Bit0!(set_enc, true)
    BasicTypes.SET.Bit16!(set_enc, true)
    BasicTypes.Message1.int64Field!(enc, Int64(-42))

    dec = BasicTypes.Message1.Decoder(typeof(buffer))
    BasicTypes.Message1.wrap!(dec, buffer, 0)
    msg_header_dec = BasicTypes.Message1.header(dec)
    @test BasicTypes.MessageHeader.schemaId(msg_header_dec) == UInt16(3)
    @test String(BasicTypes.Message1.eDTField(dec)) == "HELLO"
    @test BasicTypes.Message1.eNUMField(dec) == BasicTypes.ENUM.Value10
    set_dec = BasicTypes.Message1.sETField(dec)
    @test BasicTypes.SET.Bit0(set_dec)
    @test BasicTypes.SET.Bit16(set_dec)
    @test BasicTypes.Message1.int64Field(dec) == Int64(-42)

    offset_buf = zeros(UInt8, 256)
    offset_header = BasicTypes.MessageHeader.Encoder(offset_buf, 0)
    offset_enc = BasicTypes.Message1WithOffsets.Encoder(typeof(offset_buf))
    BasicTypes.Message1WithOffsets.wrap_and_apply_header!(offset_enc, offset_buf, 0; header=offset_header)
    BasicTypes.Message1WithOffsets.eDTField!(offset_enc, "BYTES")
    BasicTypes.Message1WithOffsets.eNUMField!(offset_enc, BasicTypes.ENUM.Value1)
    offset_set = BasicTypes.Message1WithOffsets.sETField(offset_enc)
    BasicTypes.SET.Bit26!(offset_set, true)
    BasicTypes.Message1WithOffsets.int64Field!(offset_enc, Int64(77))

    offset_dec = BasicTypes.Message1WithOffsets.Decoder(typeof(offset_buf))
    BasicTypes.Message1WithOffsets.wrap!(offset_dec, offset_buf, 0)
    @test String(BasicTypes.Message1WithOffsets.eDTField(offset_dec)) == "BYTES"
    @test BasicTypes.Message1WithOffsets.eNUMField(offset_dec) == BasicTypes.ENUM.Value1
    offset_set_dec = BasicTypes.Message1WithOffsets.sETField(offset_dec)
    @test BasicTypes.SET.Bit26(offset_set_dec)
    @test BasicTypes.Message1WithOffsets.int64Field(offset_dec) == Int64(77)
end
