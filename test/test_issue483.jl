using Test

@testset "Issue483 Constants and Optional" begin
    buffer = zeros(UInt8, 64)
    header = Issue483.MessageHeader.Encoder(buffer, 0)
    enc = Issue483.Issue483.Encoder(typeof(buffer))
    Issue483.Issue483.wrap_and_apply_header!(enc, buffer, 0; header=header)

    Issue483.Issue483.unset!(enc, UInt8(1))
    Issue483.Issue483.required!(enc, UInt8(2))
    Issue483.Issue483.optional!(enc, UInt8(3))

    dec = Issue483.Issue483.Decoder(typeof(buffer))
    Issue483.Issue483.wrap!(dec, buffer, 0)
    @test Issue483.Issue483.unset(dec) == UInt8(1)
    @test Issue483.Issue483.required(dec) == UInt8(2)
    @test Issue483.Issue483.optional(dec) == UInt8(3)
    @test Issue483.Issue483.constant(dec) == UInt8(1)
end
