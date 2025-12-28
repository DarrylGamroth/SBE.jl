using Test

@testset "Deprecated Message" begin
    buffer = zeros(UInt8, 64)
    header = DeprecatedMessage.MessageHeader.Encoder(buffer, 0)
    enc = DeprecatedMessage.DeprecatedMessage.Encoder(typeof(buffer))
    DeprecatedMessage.DeprecatedMessage.wrap_and_apply_header!(enc, buffer, 0; header=header)
    DeprecatedMessage.DeprecatedMessage.v1!(enc, UInt64(77))

    dec = DeprecatedMessage.DeprecatedMessage.Decoder(typeof(buffer))
    DeprecatedMessage.DeprecatedMessage.wrap!(dec, buffer, 0)
    @test DeprecatedMessage.DeprecatedMessage.v1(dec) == UInt64(77)
end
