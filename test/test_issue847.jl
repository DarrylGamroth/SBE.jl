using Test

@testset "Issue847 Composite Ref in Message Header" begin
    buffer = zeros(UInt8, 64)
    header = Issue847.MessageHeader.Encoder(buffer, 0)
    enc = Issue847.Barmsg.Encoder(typeof(buffer))
    Issue847.Barmsg.wrap_and_apply_header!(enc, buffer, 0; header=header)

    msg_header = Issue847.Barmsg.header(enc)
    comp = Issue847.MessageHeader.c1(msg_header)
    Issue847.Comp1.lmn!(comp, UInt16(10))
    Issue847.Comp1.wxy!(comp, UInt16(20))

    dec = Issue847.Barmsg.Decoder(typeof(buffer))
    Issue847.Barmsg.wrap!(dec, buffer, 0)
    msg_header_dec = Issue847.Barmsg.header(dec)
    comp_dec = Issue847.MessageHeader.c1(msg_header_dec)
    @test Issue847.Comp1.lmn(comp_dec) == UInt16(10)
    @test Issue847.Comp1.wxy(comp_dec) == UInt16(20)
end
