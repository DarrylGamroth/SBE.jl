using Test

@testset "ValueRef Schema" begin
    @test ValueRefSchema.TimeUnit.nanosecond == ValueRefSchema.TimeUnit.SbeEnum(UInt8(9))

    buffer = zeros(UInt8, 128)
    header = ValueRefSchema.MessageHeader.Encoder(buffer, 0)

    enc1 = ValueRefSchema.MsgOne.Encoder(buffer, 0; header=header)
    ts = ValueRefSchema.MsgOne.timestampComposite(enc1)
    ValueRefSchema.UTCTimestampNanos.time!(ts, UInt64(123))
    dec1 = ValueRefSchema.MsgOne.Decoder(buffer, 0)
    ts_dec = ValueRefSchema.MsgOne.timestampComposite(dec1)
    @test ValueRefSchema.UTCTimestampNanos.time(ts_dec) == UInt64(123)
    @test ValueRefSchema.UTCTimestampNanos.unit(ts_dec) == UInt8(ValueRefSchema.TimeUnit.nanosecond)

    enc2 = ValueRefSchema.MsgTwo.Encoder(buffer, 0; header=header)
    dec2 = ValueRefSchema.MsgTwo.Decoder(buffer, 0)
    @test ValueRefSchema.MsgTwo.timeUnitTypeOne(dec2) == UInt8(ValueRefSchema.TimeUnit.millisecond)

    enc3 = ValueRefSchema.MsgThree.Encoder(buffer, 0; header=header)
    dec3 = ValueRefSchema.MsgThree.Decoder(buffer, 0)
    @test ValueRefSchema.MsgThree.timeUnitTypeOne(dec3) == ValueRefSchema.TimeUnit.millisecond

    enc4 = ValueRefSchema.MsgFour.Encoder(buffer, 0; header=header)
    dec4 = ValueRefSchema.MsgFour.Decoder(buffer, 0)
    @test ValueRefSchema.MsgFour.testConstantOneField(dec4) == UInt8(7)

    enc5 = ValueRefSchema.MsgFive.Encoder(buffer, 0; header=header)
    dec5 = ValueRefSchema.MsgFive.Decoder(buffer, 0)
    @test ValueRefSchema.MsgFive.testConstantTwoField(dec5) == UInt8(ValueRefSchema.TimeUnit.nanosecond)
end
