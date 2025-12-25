using Test

@testset "Issue496 Nested Composite Refs" begin
    buffer = zeros(UInt8, 128)
    header = Issue496.MessageHeader.Encoder(buffer, 0)
    enc = Issue496.SomeMessage.Encoder(buffer, 0; header=header)

    Issue496.SomeMessage.id!(enc, Int64(7))
    comp = Issue496.SomeMessage.comp(enc)
    Issue496.CompositeOne.compFieldOne!(comp, "AAAA")

    comp_two = Issue496.CompositeOne.compTwo(comp)
    Issue496.CompositeTwo.compFieldTwo!(comp_two, "BBBB")

    comp_three = Issue496.CompositeTwo.compThree(comp_two)
    Issue496.CompositeThree.field1!(comp_three, "CCCC")

    dec = Issue496.SomeMessage.Decoder(buffer, 0)
    @test Issue496.SomeMessage.id(dec) == Int64(7)
    comp_dec = Issue496.SomeMessage.comp(dec)
    @test String(Issue496.CompositeOne.compFieldOne(comp_dec)) == "AAAA"

    comp_two_dec = Issue496.CompositeOne.compTwo(comp_dec)
    @test String(Issue496.CompositeTwo.compFieldTwo(comp_two_dec)) == "BBBB"

    comp_three_dec = Issue496.CompositeTwo.compThree(comp_two_dec)
    @test String(Issue496.CompositeThree.field1(comp_three_dec)) == "CCCC"
end
