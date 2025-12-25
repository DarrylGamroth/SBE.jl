using Test

@testset "Big Endian Baseline Schema" begin
    buffer = zeros(UInt8, 512)
    header = BigEndianBaseline.MessageHeader.Encoder(buffer, 0)
    enc = BigEndianBaseline.Car.Encoder(buffer, 0; header=header)

    BigEndianBaseline.Car.serialNumber!(enc, UInt64(0x1122334455667788))
    BigEndianBaseline.Car.modelYear!(enc, UInt16(2024))
    BigEndianBaseline.Car.available!(enc, BigEndianBaseline.BooleanType.T)
    BigEndianBaseline.Car.code!(enc, BigEndianBaseline.Model.B)

    nums = BigEndianBaseline.Car.someNumbers!(enc)
    copyto!(nums, UInt32[1, 2, 3, 4, 5])

    BigEndianBaseline.Car.vehicleCode!(enc, "ABC123")
    extras = BigEndianBaseline.Car.extras(enc)
    BigEndianBaseline.OptionalExtras.sunRoof!(extras, true)
    BigEndianBaseline.OptionalExtras.cruiseControl!(extras, true)

    engine = BigEndianBaseline.Car.engine(enc)
    BigEndianBaseline.Engine.capacity!(engine, UInt16(2000))
    BigEndianBaseline.Engine.numCylinders!(engine, UInt8(4))
    BigEndianBaseline.Engine.efficiency!(engine, Int8(95))
    BigEndianBaseline.Engine.boosterEnabled!(engine, BigEndianBaseline.BooleanType.F)
    booster = BigEndianBaseline.Engine.booster(engine)
    BigEndianBaseline.Booster.horsePower!(booster, UInt8(15))
    BigEndianBaseline.Booster.boostType!(booster, BigEndianBaseline.BoostType.TURBO)

    dec = BigEndianBaseline.Car.Decoder(buffer, 0)
    @test BigEndianBaseline.Car.serialNumber(dec) == UInt64(0x1122334455667788)
    @test BigEndianBaseline.Car.modelYear(dec) == UInt16(2024)
    @test BigEndianBaseline.Car.available(dec) == BigEndianBaseline.BooleanType.T
    @test BigEndianBaseline.Car.code(dec) == BigEndianBaseline.Model.B
    @test collect(BigEndianBaseline.Car.someNumbers(dec)) == UInt32[1, 2, 3, 4, 5]
    @test String(BigEndianBaseline.Car.vehicleCode(dec)) == "ABC123"
    extras_dec = BigEndianBaseline.Car.extras(dec)
    @test BigEndianBaseline.OptionalExtras.sunRoof(extras_dec)
    @test BigEndianBaseline.OptionalExtras.cruiseControl(extras_dec)

    engine_dec = BigEndianBaseline.Car.engine(dec)
    @test BigEndianBaseline.Engine.capacity(engine_dec) == UInt16(2000)
    @test BigEndianBaseline.Engine.numCylinders(engine_dec) == UInt8(4)
    @test BigEndianBaseline.Engine.efficiency(engine_dec) == Int8(95)
    @test BigEndianBaseline.Engine.boosterEnabled(engine_dec) == BigEndianBaseline.BooleanType.F
    booster_dec = BigEndianBaseline.Engine.booster(engine_dec)
    @test BigEndianBaseline.Booster.horsePower(booster_dec) == UInt8(15)
    @test BigEndianBaseline.Booster.boostType(booster_dec) == BigEndianBaseline.BoostType.TURBO
end
