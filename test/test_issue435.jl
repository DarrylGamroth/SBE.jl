using Test

@testset "Issue435 Enum/Set References" begin
    buffer = zeros(UInt8, 64)
    header = Issue435.MessageHeader.Encoder(buffer, 0)
    enc = Issue435.Issue435.Encoder(buffer, 0; header=header)

    example = Issue435.Issue435.example(enc)
    Issue435.ExampleRef.e!(example, Issue435.EnumRef.Two)

    dec = Issue435.Issue435.Decoder(buffer, 0)
    example_dec = Issue435.Issue435.example(dec)
    @test Issue435.ExampleRef.e(example_dec) == Issue435.EnumRef.Two
end
