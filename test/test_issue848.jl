using Test

@testset "Issue848 Composite Ref in Message and Header" begin
    buffer = zeros(UInt8, 96)
    header = Issue848.MessageHeader.Encoder(buffer, 0)
    enc = Issue848.Barmsg.Encoder(buffer, 0; header=header)

    msg_header = Issue848.Barmsg.header(enc)
    header_c1 = Issue848.MessageHeader.c1(msg_header)
    Issue848.Comp1.lmn!(header_c1, UInt16(1))
    Issue848.Comp1.wxy!(header_c1, UInt16(2))

    c2 = Issue848.Barmsg.c2(enc)
    c2_c1 = Issue848.Comp2.c1(c2)
    Issue848.Comp1.lmn!(c2_c1, UInt16(3))
    Issue848.Comp1.wxy!(c2_c1, UInt16(4))

    dec = Issue848.Barmsg.Decoder(buffer, 0)
    msg_header_dec = Issue848.Barmsg.header(dec)
    header_c1_dec = Issue848.MessageHeader.c1(msg_header_dec)
    @test Issue848.Comp1.lmn(header_c1_dec) == UInt16(1)
    @test Issue848.Comp1.wxy(header_c1_dec) == UInt16(2)

    c2_dec = Issue848.Barmsg.c2(dec)
    c2_c1_dec = Issue848.Comp2.c1(c2_dec)
    @test Issue848.Comp1.lmn(c2_c1_dec) == UInt16(3)
    @test Issue848.Comp1.wxy(c2_c1_dec) == UInt16(4)
end
