using Test

@testset "Since Deprecated Versions" begin
    buffer = zeros(UInt8, 64)
    header = SinceDeprecated.MessageHeader.Encoder(buffer, 0)
    enc = SinceDeprecated.SinceDeprecated.Encoder(typeof(buffer))
    SinceDeprecated.SinceDeprecated.wrap_and_apply_header!(enc, buffer, 0; header=header)

    SinceDeprecated.SinceDeprecated.v1!(enc, UInt64(1))
    SinceDeprecated.SinceDeprecated.v2!(enc, UInt64(2))
    SinceDeprecated.SinceDeprecated.v3!(enc, UInt64(3))

    SinceDeprecated.MessageHeader.version!(header, UInt16(1))
    dec_v1 = SinceDeprecated.SinceDeprecated.Decoder(typeof(buffer))
    SinceDeprecated.SinceDeprecated.wrap!(dec_v1, buffer, 0)
    @test SinceDeprecated.SinceDeprecated.v1_in_acting_version(dec_v1)
    @test !SinceDeprecated.SinceDeprecated.v2_in_acting_version(dec_v1)
    @test !SinceDeprecated.SinceDeprecated.v3_in_acting_version(dec_v1)

    SinceDeprecated.MessageHeader.version!(header, UInt16(2))
    dec_v2 = SinceDeprecated.SinceDeprecated.Decoder(typeof(buffer))
    SinceDeprecated.SinceDeprecated.wrap!(dec_v2, buffer, 0)
    @test SinceDeprecated.SinceDeprecated.v2_in_acting_version(dec_v2)
    @test !SinceDeprecated.SinceDeprecated.v3_in_acting_version(dec_v2)

    SinceDeprecated.MessageHeader.version!(header, UInt16(4))
    dec_v4 = SinceDeprecated.SinceDeprecated.Decoder(typeof(buffer))
    SinceDeprecated.SinceDeprecated.wrap!(dec_v4, buffer, 0)
    @test SinceDeprecated.SinceDeprecated.v3_in_acting_version(dec_v4)
    @test SinceDeprecated.SinceDeprecated.v1(dec_v4) == UInt64(1)
    @test SinceDeprecated.SinceDeprecated.v2(dec_v4) == UInt64(2)
    @test SinceDeprecated.SinceDeprecated.v3(dec_v4) == UInt64(3)
end
