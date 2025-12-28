using Test

@testset "Basic Variable Length Schema" begin
    buffer = zeros(UInt8, 128)
    header = BasicVariableLength.MessageHeader.Encoder(buffer, 0)
    enc = BasicVariableLength.TestMessage1.Encoder(typeof(buffer))
    BasicVariableLength.TestMessage1.wrap_and_apply_header!(enc, buffer, 0; header=header)

    BasicVariableLength.TestMessage1.encryptedNewPassword!(enc, "secret")

    dec = BasicVariableLength.TestMessage1.Decoder(typeof(buffer))
    BasicVariableLength.TestMessage1.wrap!(dec, buffer, 0)
    @test BasicVariableLength.TestMessage1.encryptedNewPassword_length(dec) == 6
    @test BasicVariableLength.TestMessage1.encryptedNewPassword(dec, String) == "secret"
end
