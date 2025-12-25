using Test

@testset "Issue1007 Keyword Enum Values" begin
    buffer = zeros(UInt8, 64)
    header = Issue1007.MessageHeader.Encoder(buffer, 0)
    enc = Issue1007.Issue1007.Encoder(buffer, 0; header=header)

    Issue1007.Issue1007.constant!(enc, Issue1007.MyEnum.true_)

    dec = Issue1007.Issue1007.Decoder(buffer, 0)
    @test Issue1007.Issue1007.constant(dec) == Issue1007.MyEnum.true_
    @test Issue1007.MyEnum.false_ != Issue1007.MyEnum.true_
end
