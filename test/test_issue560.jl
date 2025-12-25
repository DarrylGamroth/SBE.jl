using Test

@testset "Issue560 Constant Enum ValueRef" begin
    buffer = zeros(UInt8, 64)
    header = Issue560.MessageHeader.Encoder(buffer, 0)
    Issue560.Issue560.Encoder(buffer, 0; header=header)

    dec = Issue560.Issue560.Decoder(buffer, 0)
    @test Issue560.Issue560.discountedModel(dec) == Issue560.Model.C
end
