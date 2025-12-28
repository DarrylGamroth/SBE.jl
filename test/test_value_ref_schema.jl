using Test

@testset "ValueRef Schema" begin
    @test ValueRefSchema.TimeUnit.nanosecond == ValueRefSchema.TimeUnit.SbeEnum(UInt8(9))

    buffer = zeros(UInt8, 128)
    header = ValueRefSchema.MessageHeader.Encoder(buffer, 0)

    enc1 = ValueRefSchema.MsgOne.Encoder(typeof(buffer))
    ValueRefSchema.MsgOne.wrap_and_apply_header!(enc1, buffer, 0; header=header)
    ts = ValueRefSchema.MsgOne.timestampComposite(enc1)
    ValueRefSchema.UTCTimestampNanos.time!(ts, UInt64(123))
    dec1 = ValueRefSchema.MsgOne.Decoder(typeof(buffer))
    ValueRefSchema.MsgOne.wrap!(dec1, buffer, 0)
    ts_dec = ValueRefSchema.MsgOne.timestampComposite(dec1)
    @test ValueRefSchema.UTCTimestampNanos.time(ts_dec) == UInt64(123)
    @test ValueRefSchema.UTCTimestampNanos.unit(ts_dec) == UInt8(ValueRefSchema.TimeUnit.nanosecond)

    enc2 = ValueRefSchema.MsgTwo.Encoder(typeof(buffer))
    ValueRefSchema.MsgTwo.wrap_and_apply_header!(enc2, buffer, 0; header=header)
    dec2 = ValueRefSchema.MsgTwo.Decoder(typeof(buffer))
    ValueRefSchema.MsgTwo.wrap!(dec2, buffer, 0)
    @test ValueRefSchema.MsgTwo.timeUnitTypeOne(dec2) == UInt8(ValueRefSchema.TimeUnit.millisecond)

    enc3 = ValueRefSchema.MsgThree.Encoder(typeof(buffer))
    ValueRefSchema.MsgThree.wrap_and_apply_header!(enc3, buffer, 0; header=header)
    dec3 = ValueRefSchema.MsgThree.Decoder(typeof(buffer))
    ValueRefSchema.MsgThree.wrap!(dec3, buffer, 0)
    @test ValueRefSchema.MsgThree.timeUnitTypeOne(dec3) == ValueRefSchema.TimeUnit.millisecond

    enc4 = ValueRefSchema.MsgFour.Encoder(typeof(buffer))
    ValueRefSchema.MsgFour.wrap_and_apply_header!(enc4, buffer, 0; header=header)
    dec4 = ValueRefSchema.MsgFour.Decoder(typeof(buffer))
    ValueRefSchema.MsgFour.wrap!(dec4, buffer, 0)
    @test ValueRefSchema.MsgFour.testConstantOneField(dec4) == UInt8(7)

    enc5 = ValueRefSchema.MsgFive.Encoder(typeof(buffer))
    ValueRefSchema.MsgFive.wrap_and_apply_header!(enc5, buffer, 0; header=header)
    dec5 = ValueRefSchema.MsgFive.Decoder(typeof(buffer))
    ValueRefSchema.MsgFive.wrap!(dec5, buffer, 0)
    @test ValueRefSchema.MsgFive.testConstantTwoField(dec5) == UInt8(ValueRefSchema.TimeUnit.nanosecond)
end
