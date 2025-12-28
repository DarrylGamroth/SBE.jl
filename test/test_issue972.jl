using Test

@testset "Issue972 Optional Composite SinceVersion" begin
    buffer = zeros(UInt8, 64)
    header = Issue972.MessageHeader.Encoder(buffer, 0)
    enc = Issue972.Issue972.Encoder(typeof(buffer))
    Issue972.Issue972.wrap_and_apply_header!(enc, buffer, 0; header=header)

    comp = Issue972.Issue972.newField(enc)
    Issue972.NewComposite.f1!(comp, UInt16(10))
    Issue972.NewComposite.f2!(comp, UInt32(20))

    dec = Issue972.Issue972.Decoder(typeof(buffer))
    Issue972.Issue972.wrap!(dec, buffer, 0)
    comp_dec = Issue972.Issue972.newField(dec)
    @test Issue972.NewComposite.f1(comp_dec) == UInt16(10)
    @test Issue972.NewComposite.f2(comp_dec) == UInt32(20)

    dec0 = Issue972.Issue972.Decoder(typeof(buffer))
    dec0.position_ptr = SBE.PositionPointer()
    Issue972.Issue972.wrap!(dec0, buffer, 0, UInt16(0), UInt16(0))
    @test !Issue972.Issue972.newField_in_acting_version(dec0)

    dec1 = Issue972.Issue972.Decoder(typeof(buffer))
    dec1.position_ptr = SBE.PositionPointer()
    Issue972.Issue972.wrap!(dec1, buffer, 0, UInt16(0), UInt16(1))
    @test Issue972.Issue972.newField_in_acting_version(dec1)
end
