using Test

@testset "Issue488 VarData" begin
    buffer = zeros(UInt8, 64)
    header = Issue488Schema.MessageHeader.Encoder(buffer, 0)
    enc = Issue488Schema.Issue488.Encoder(buffer, 0; header=header)

    Issue488Schema.Issue488.varData!(enc, UInt8[0x01, 0x02, 0x03])

    dec = Issue488Schema.Issue488.Decoder(buffer, 0)
    @test Issue488Schema.Issue488.varData(dec) == UInt8[0x01, 0x02, 0x03]
end
