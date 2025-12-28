using Test

@testset "Composite Offsets" begin
    buffer = zeros(UInt8, 128)
    header = CompositeOffsets.MessageHeader.Encoder(buffer, 0)
    enc = CompositeOffsets.TestMessage2.Encoder(typeof(buffer))
    CompositeOffsets.TestMessage2.wrap_and_apply_header!(enc, buffer, 0; header=header)

    CompositeOffsets.TestMessage2.fieldOne!(enc, Int32(7))
    composite = CompositeOffsets.TestMessage2.fieldTwo(enc)
    CompositeOffsets.TestComposite.compositeFieldOne!(composite, UInt8(1))
    CompositeOffsets.TestComposite.compositeFieldTwo!(composite, Int64(42))
    CompositeOffsets.TestMessage2.fieldThree!(enc, Int64(99))

    dec = CompositeOffsets.TestMessage2.Decoder(typeof(buffer))
    CompositeOffsets.TestMessage2.wrap!(dec, buffer, 0)
    @test CompositeOffsets.TestMessage2.fieldOne(dec) == Int32(7)
    composite_dec = CompositeOffsets.TestMessage2.fieldTwo(dec)
    @test CompositeOffsets.TestComposite.compositeFieldOne(composite_dec) == UInt8(1)
    @test CompositeOffsets.TestComposite.compositeFieldTwo(composite_dec) == Int64(42)
    @test CompositeOffsets.TestMessage2.fieldThree(dec) == Int64(99)
end
