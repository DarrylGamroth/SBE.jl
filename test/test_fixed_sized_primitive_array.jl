using Test

@testset "Fixed Sized Primitive Array" begin
    buffer = zeros(UInt8, 512)
    header = FixedSizedPrimitiveArray.MessageHeader.Encoder(buffer, 0)
    enc = FixedSizedPrimitiveArray.Demo.Encoder(typeof(buffer))
    FixedSizedPrimitiveArray.Demo.wrap_and_apply_header!(enc, buffer, 0; header=header)

    FixedSizedPrimitiveArray.Demo.fixed16Char!(enc, "HELLO")
    FixedSizedPrimitiveArray.Demo.fixed16U8!(enc, UInt8[1,2,3])
    FixedSizedPrimitiveArray.Demo.fixed16i16!(enc, Int16[1,2,3])

    dec = FixedSizedPrimitiveArray.Demo.Decoder(typeof(buffer))
    FixedSizedPrimitiveArray.Demo.wrap!(dec, buffer, 0)
    @test String(FixedSizedPrimitiveArray.Demo.fixed16Char(dec)) == "HELLO"
    @test FixedSizedPrimitiveArray.Demo.fixed16U8(dec)[1:3] == UInt8[1,2,3]
    @test FixedSizedPrimitiveArray.Demo.fixed16i16(dec)[1:3] == Int16[1,2,3]
    buffer2 = zeros(UInt8, 512)
    header2 = FixedSizedPrimitiveArray.MessageHeader.Encoder(buffer2, 0)
    enc2 = FixedSizedPrimitiveArray.Demo.Encoder(typeof(buffer2))
    FixedSizedPrimitiveArray.Demo.wrap_and_apply_header!(enc2, buffer2, 0; header=header2)
    FixedSizedPrimitiveArray.Demo.fixed16U8!(enc2, ntuple(UInt8, 16))

    dec2 = FixedSizedPrimitiveArray.Demo.Decoder(typeof(buffer2))
    FixedSizedPrimitiveArray.Demo.wrap!(dec2, buffer2, 0)
    tuple_u8 = FixedSizedPrimitiveArray.Demo.fixed16U8(dec2, NTuple{16,UInt8})
    @test tuple_u8 == ntuple(UInt8, 16)
    @test @allocated(FixedSizedPrimitiveArray.Demo.fixed16U8(dec2, NTuple{16,UInt8})) == 0
end
