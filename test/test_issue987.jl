using Test

@testset "Issue987 Composite Offsets" begin
    buffer = zeros(UInt8, 64)
    header = Issue987.MessageHeader.Encoder(buffer, 0)
    enc = Issue987.Issue987.Encoder(buffer, 0; header=header)

    comp = Issue987.Issue987.newField(enc)
    Issue987.NewComposite.f1!(comp, UInt16(123))
    Issue987.NewComposite.f2!(comp, UInt32(456))

    dec = Issue987.Issue987.Decoder(buffer, 0)
    comp_dec = Issue987.Issue987.newField(dec)
    @test Issue987.NewComposite.f1(comp_dec) == UInt16(123)
    @test Issue987.NewComposite.f2(comp_dec) == UInt32(456)
end
