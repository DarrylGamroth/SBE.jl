using Test

@testset "Issue895 Optional Float/Double" begin
    buffer = zeros(UInt8, 64)
    header = Issue895.MessageHeader.Encoder(buffer, 0)
    enc = Issue895.Issue895.Encoder(buffer, 0; header=header)
    Issue895.Issue895.optionalFloat!(enc, Float32(1.5))
    Issue895.Issue895.optionalDouble!(enc, Float64(2.5))

    dec = Issue895.Issue895.Decoder(buffer, 0)
    @test Issue895.Issue895.optionalFloat(dec) == Float32(1.5)
    @test Issue895.Issue895.optionalDouble(dec) == Float64(2.5)

    null_buffer = zeros(UInt8, 64)
    null_header = Issue895.MessageHeader.Encoder(null_buffer, 0)
    null_enc = Issue895.Issue895.Encoder(null_buffer, 0; header=null_header)
    Issue895.Issue895.optionalFloat!(null_enc, Issue895.Issue895.optionalFloat_null_value(null_enc))
    Issue895.Issue895.optionalDouble!(null_enc, Issue895.Issue895.optionalDouble_null_value(null_enc))

    null_dec = Issue895.Issue895.Decoder(null_buffer, 0)
    @test isnan(Issue895.Issue895.optionalFloat(null_dec))
    @test isnan(Issue895.Issue895.optionalDouble(null_dec))
end
