using Test

@testset "Issue1066 Optional Field SinceVersion" begin
    buffer = zeros(UInt8, 32)
    header = Issue1066.MessageHeader.Encoder(buffer, 0)
    enc = Issue1066.Issue1066.Encoder(buffer, 0; header=header)
    Issue1066.Issue1066.field!(enc, UInt16(7))

    dec = Issue1066.Issue1066.Decoder(buffer, 0)
    @test Issue1066.Issue1066.field(dec) == UInt16(7)

    Issue1066.MessageHeader.version!(header, UInt16(1))
    dec1 = Issue1066.Issue1066.Decoder(buffer, 0)
    @test !Issue1066.Issue1066.field_in_acting_version(dec1)
end
