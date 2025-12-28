using Test

@testset "Issue661 SinceVersion Set" begin
    buffer = zeros(UInt8, 64)

    dec0 = Issue661.Issue661.Decoder(typeof(buffer))
    dec0.position_ptr = SBE.PositionPointer()
    Issue661.Issue661.wrap!(dec0, buffer, 0, UInt16(0), UInt16(0))
    @test !Issue661.Issue661.set1_in_acting_version(dec0)

    dec1 = Issue661.Issue661.Decoder(typeof(buffer))
    dec1.position_ptr = SBE.PositionPointer()
    Issue661.Issue661.wrap!(dec1, buffer, 0, UInt16(0), UInt16(1))
    @test Issue661.Issue661.set1_in_acting_version(dec1)

    header = Issue661.MessageHeader.Encoder(buffer, 0)
    enc = Issue661.Issue661.Encoder(typeof(buffer))
    Issue661.Issue661.wrap_and_apply_header!(enc, buffer, 0; header=header)

    set0 = Issue661.Issue661.set0(enc)
    Issue661.Set_.One!(set0, true)

    set1 = Issue661.Issue661.set1(enc)
    Issue661.Set_.Two!(set1, true)

    dec = Issue661.Issue661.Decoder(typeof(buffer))
    Issue661.Issue661.wrap!(dec, buffer, 0)
    set0d = Issue661.Issue661.set0(dec)
    set1d = Issue661.Issue661.set1(dec)

    @test Issue661.Set_.One(set0d)
    @test Issue661.Set_.Two(set1d)
end
