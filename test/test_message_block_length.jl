using Test

@testset "Message Block Length" begin
    buffer = zeros(UInt8, 128)
    header = MessageBlockLengthTest.MessageHeader.Encoder(buffer, 0)
    enc = MessageBlockLengthTest.MsgName.Encoder(typeof(buffer))
    MessageBlockLengthTest.MsgName.wrap_and_apply_header!(enc, buffer, 0; header=header)

    @test MessageBlockLengthTest.MsgName.sbe_block_length(enc) == UInt16(11)
    @test MessageBlockLengthTest.MsgName.sbe_encoded_length(enc) == UInt16(11)

    msg_dec = MessageBlockLengthTest.MsgName.Decoder(typeof(buffer))
    MessageBlockLengthTest.MsgName.wrap!(msg_dec, buffer, 0)
    @test MessageBlockLengthTest.MsgName.sbe_acting_block_length(msg_dec) == UInt16(11)
end
