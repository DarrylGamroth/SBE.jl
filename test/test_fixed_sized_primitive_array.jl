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
end
