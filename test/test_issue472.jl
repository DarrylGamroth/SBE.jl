using Test

@testset "Issue472 Optional UInt64" begin
    buffer = zeros(UInt8, 64)
    header = Issue472.MessageHeader.Encoder(buffer, 0)
    enc = Issue472.Issue472.Encoder(typeof(buffer))
    Issue472.Issue472.wrap_and_apply_header!(enc, buffer, 0; header=header)

    Issue472.Issue472.optional!(enc, UInt64(123))

    dec = Issue472.Issue472.Decoder(typeof(buffer))
    Issue472.Issue472.wrap!(dec, buffer, 0)
    @test Issue472.Issue472.optional(dec) == UInt64(123)
end
