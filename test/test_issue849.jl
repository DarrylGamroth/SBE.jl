using Test

@testset "Issue849 Deep Composite Refs" begin
    buffer = zeros(UInt8, 256)
    header = Issue849.MessageHeader.Encoder(buffer, 0)
    enc = Issue849.Barmsg.Encoder(typeof(buffer))
    Issue849.Barmsg.wrap_and_apply_header!(enc, buffer, 0; header=header)

    msg_header = Issue849.Barmsg.header(enc)
    header_c1 = Issue849.MessageHeader.c1(msg_header)
    Issue849.Comp1.abc!(header_c1, UInt32(1))
    Issue849.Comp1.wxyz!(header_c1, UInt32(2))
    Issue849.MessageHeader.lmn!(msg_header, UInt32(3))

    header_c2 = Issue849.MessageHeader.c2(msg_header)
    Issue849.Comp2.eenie!(header_c2, UInt32(4))
    header_c2_c1 = Issue849.Comp2.c1(header_c2)
    Issue849.Comp1.abc!(header_c2_c1, UInt32(5))
    Issue849.Comp1.wxyz!(header_c2_c1, UInt32(6))
    Issue849.Comp2.meanie!(header_c2, UInt32(7))
    Issue849.MessageHeader.opq!(msg_header, UInt32(8))

    c3 = Issue849.Barmsg.c3(enc)
    Issue849.Comp3.moe!(c3, UInt32(9))
    c3_c2 = Issue849.Comp3.c2(c3)
    Issue849.Comp2.eenie!(c3_c2, UInt32(10))
    c3_c2_c1 = Issue849.Comp2.c1(c3_c2)
    Issue849.Comp1.abc!(c3_c2_c1, UInt32(11))
    Issue849.Comp1.wxyz!(c3_c2_c1, UInt32(12))
    Issue849.Comp2.meanie!(c3_c2, UInt32(13))
    Issue849.Comp3.roe!(c3, UInt32(14))

    c4 = Issue849.Barmsg.c4(enc)
    Issue849.Comp4.roe!(c4, UInt32(15))

    dec = Issue849.Barmsg.Decoder(typeof(buffer))
    Issue849.Barmsg.wrap!(dec, buffer, 0)
    msg_header_dec = Issue849.Barmsg.header(dec)
    header_c1_dec = Issue849.MessageHeader.c1(msg_header_dec)
    @test Issue849.Comp1.abc(header_c1_dec) == UInt32(1)
    @test Issue849.Comp1.wxyz(header_c1_dec) == UInt32(2)
    @test Issue849.MessageHeader.lmn(msg_header_dec) == UInt32(3)

    header_c2_dec = Issue849.MessageHeader.c2(msg_header_dec)
    @test Issue849.Comp2.eenie(header_c2_dec) == UInt32(4)
    header_c2_c1_dec = Issue849.Comp2.c1(header_c2_dec)
    @test Issue849.Comp1.abc(header_c2_c1_dec) == UInt32(5)
    @test Issue849.Comp1.wxyz(header_c2_c1_dec) == UInt32(6)
    @test Issue849.Comp2.meanie(header_c2_dec) == UInt32(7)
    @test Issue849.MessageHeader.opq(msg_header_dec) == UInt32(8)

    c3_dec = Issue849.Barmsg.c3(dec)
    @test Issue849.Comp3.moe(c3_dec) == UInt32(9)
    c3_c2_dec = Issue849.Comp3.c2(c3_dec)
    @test Issue849.Comp2.eenie(c3_c2_dec) == UInt32(10)
    c3_c2_c1_dec = Issue849.Comp2.c1(c3_c2_dec)
    @test Issue849.Comp1.abc(c3_c2_c1_dec) == UInt32(11)
    @test Issue849.Comp1.wxyz(c3_c2_c1_dec) == UInt32(12)
    @test Issue849.Comp2.meanie(c3_c2_dec) == UInt32(13)
    @test Issue849.Comp3.roe(c3_dec) == UInt32(14)

    c4_dec = Issue849.Barmsg.c4(dec)
    @test Issue849.Comp4.roe(c4_dec) == UInt32(15)
end
