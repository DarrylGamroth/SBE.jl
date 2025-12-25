using Test
using SBE

module FixtureGenerated
    include(joinpath(@__DIR__, "generated", "Baseline.jl"))
    using .Baseline
end

const FixtureBaseline = FixtureGenerated.Baseline

@testset "Java Fixture Parity" begin
    fixture_path = joinpath(@__DIR__, "java-fixtures", "car-example.bin")
    @test isfile(fixture_path)
    bytes = read(fixture_path)

    dec = FixtureBaseline.Car.Decoder(bytes, 0)

    @test FixtureBaseline.Car.serialNumber(dec) == UInt64(1234)
    @test FixtureBaseline.Car.modelYear(dec) == UInt16(2013)
    @test FixtureBaseline.Car.available(dec) == FixtureBaseline.BooleanType.T
    @test FixtureBaseline.Car.code(dec) == FixtureBaseline.Model.A

    some_numbers = FixtureBaseline.Car.someNumbers(dec)
    @test collect(some_numbers) == UInt32[1, 2, 3, 4]

    @test FixtureBaseline.Car.vehicleCode(dec) == "abcdef"

    extras = FixtureBaseline.Car.extras(dec)
    @test FixtureBaseline.OptionalExtras.cruiseControl(extras) == true
    @test FixtureBaseline.OptionalExtras.sportsPack(extras) == true
    @test FixtureBaseline.OptionalExtras.sunRoof(extras) == false

    @test FixtureBaseline.Car.discountedModel(dec) == FixtureBaseline.Model.C

    engine = FixtureBaseline.Car.engine(dec)
    @test FixtureBaseline.Engine.capacity(engine) == UInt16(2000)
    @test FixtureBaseline.Engine.numCylinders(engine) == UInt8(4)
    @test FixtureBaseline.Engine.manufacturerCode(engine) == "123"
    @test FixtureBaseline.Engine.maxRpm(engine) == UInt16(9000)
    @test String(FixtureBaseline.Engine.fuel(engine)) == "Petrol"
    @test FixtureBaseline.Engine.efficiency(engine) == Int8(35)
    @test FixtureBaseline.Engine.boosterEnabled(engine) == FixtureBaseline.BooleanType.T

    booster = FixtureBaseline.Engine.booster(engine)
    @test FixtureBaseline.Booster.boostType(booster) == FixtureBaseline.Booster.BoostType.NITROUS
    @test FixtureBaseline.Booster.horsePower(booster) == UInt8(200)

    fuel = FixtureBaseline.Car.fuelFigures(dec)
    @test length(fuel) == 3
    FixtureBaseline.Car.FuelFigures.next!(fuel)
    @test FixtureBaseline.Car.FuelFigures.speed(fuel) == UInt16(30)
    @test FixtureBaseline.Car.FuelFigures.mpg(fuel) == Float32(35.9)
    @test String(FixtureBaseline.Car.FuelFigures.usageDescription(fuel)) == "Urban Cycle"

    FixtureBaseline.Car.FuelFigures.next!(fuel)
    @test FixtureBaseline.Car.FuelFigures.speed(fuel) == UInt16(55)
    @test FixtureBaseline.Car.FuelFigures.mpg(fuel) == Float32(49.0)
    @test String(FixtureBaseline.Car.FuelFigures.usageDescription(fuel)) == "Combined Cycle"

    FixtureBaseline.Car.FuelFigures.next!(fuel)
    @test FixtureBaseline.Car.FuelFigures.speed(fuel) == UInt16(75)
    @test FixtureBaseline.Car.FuelFigures.mpg(fuel) == Float32(40.0)
    @test String(FixtureBaseline.Car.FuelFigures.usageDescription(fuel)) == "Highway Cycle"

    perf = FixtureBaseline.Car.performanceFigures(dec)
    @test length(perf) == 2

    FixtureBaseline.Car.PerformanceFigures.next!(perf)
    @test FixtureBaseline.Car.PerformanceFigures.octaneRating(perf) == UInt8(95)
    accel = FixtureBaseline.Car.PerformanceFigures.acceleration(perf)
    @test length(accel) == 3
    FixtureBaseline.Car.PerformanceFigures.Acceleration.next!(accel)
    @test FixtureBaseline.Car.PerformanceFigures.Acceleration.mph(accel) == UInt16(30)
    @test FixtureBaseline.Car.PerformanceFigures.Acceleration.seconds(accel) == Float32(4.0)
    FixtureBaseline.Car.PerformanceFigures.Acceleration.next!(accel)
    @test FixtureBaseline.Car.PerformanceFigures.Acceleration.mph(accel) == UInt16(60)
    @test FixtureBaseline.Car.PerformanceFigures.Acceleration.seconds(accel) == Float32(7.5)
    FixtureBaseline.Car.PerformanceFigures.Acceleration.next!(accel)
    @test FixtureBaseline.Car.PerformanceFigures.Acceleration.mph(accel) == UInt16(100)
    @test FixtureBaseline.Car.PerformanceFigures.Acceleration.seconds(accel) == Float32(12.2)

    FixtureBaseline.Car.PerformanceFigures.next!(perf)
    @test FixtureBaseline.Car.PerformanceFigures.octaneRating(perf) == UInt8(99)
    accel = FixtureBaseline.Car.PerformanceFigures.acceleration(perf)
    @test length(accel) == 3
    FixtureBaseline.Car.PerformanceFigures.Acceleration.next!(accel)
    @test FixtureBaseline.Car.PerformanceFigures.Acceleration.mph(accel) == UInt16(30)
    @test FixtureBaseline.Car.PerformanceFigures.Acceleration.seconds(accel) == Float32(3.8)
    FixtureBaseline.Car.PerformanceFigures.Acceleration.next!(accel)
    @test FixtureBaseline.Car.PerformanceFigures.Acceleration.mph(accel) == UInt16(60)
    @test FixtureBaseline.Car.PerformanceFigures.Acceleration.seconds(accel) == Float32(7.1)
    FixtureBaseline.Car.PerformanceFigures.Acceleration.next!(accel)
    @test FixtureBaseline.Car.PerformanceFigures.Acceleration.mph(accel) == UInt16(100)
    @test FixtureBaseline.Car.PerformanceFigures.Acceleration.seconds(accel) == Float32(11.8)

    @test String(FixtureBaseline.Car.manufacturer(dec)) == "Honda"
    @test String(FixtureBaseline.Car.model(dec)) == "Civic VTi"
    @test String(FixtureBaseline.Car.activationCode(dec)) == "abcdef"

    buffer = zeros(UInt8, 4096)
    enc = FixtureBaseline.Car.Encoder(buffer, 0)

    FixtureBaseline.Car.serialNumber!(enc, UInt64(1234))
    FixtureBaseline.Car.modelYear!(enc, UInt16(2013))
    FixtureBaseline.Car.available!(enc, FixtureBaseline.BooleanType.T)
    FixtureBaseline.Car.code!(enc, FixtureBaseline.Model.A)

    nums = FixtureBaseline.Car.someNumbers!(enc)
    nums[1] = UInt32(1)
    nums[2] = UInt32(2)
    nums[3] = UInt32(3)
    nums[4] = UInt32(4)

    FixtureBaseline.Car.vehicleCode!(enc, "abcdef")

    extras_enc = FixtureBaseline.Car.extras(enc)
    FixtureBaseline.OptionalExtras.cruiseControl!(extras_enc, true)
    FixtureBaseline.OptionalExtras.sportsPack!(extras_enc, true)
    FixtureBaseline.OptionalExtras.sunRoof!(extras_enc, false)

    engine_enc = FixtureBaseline.Car.engine(enc)
    FixtureBaseline.Engine.capacity!(engine_enc, UInt16(2000))
    FixtureBaseline.Engine.numCylinders!(engine_enc, UInt8(4))
    FixtureBaseline.Engine.manufacturerCode!(engine_enc, "123")
    FixtureBaseline.Engine.efficiency!(engine_enc, Int8(35))
    FixtureBaseline.Engine.boosterEnabled!(engine_enc, FixtureBaseline.BooleanType.T)

    booster_enc = FixtureBaseline.Engine.booster(engine_enc)
    FixtureBaseline.Booster.boostType!(booster_enc, FixtureBaseline.Booster.BoostType.NITROUS)
    FixtureBaseline.Booster.horsePower!(booster_enc, UInt8(200))

    fuel_enc = FixtureBaseline.Car.fuelFigures!(enc, 3)
    FixtureBaseline.Car.FuelFigures.next!(fuel_enc)
    FixtureBaseline.Car.FuelFigures.speed!(fuel_enc, UInt16(30))
    FixtureBaseline.Car.FuelFigures.mpg!(fuel_enc, Float32(35.9))
    FixtureBaseline.Car.FuelFigures.usageDescription!(fuel_enc, "Urban Cycle")
    FixtureBaseline.Car.FuelFigures.next!(fuel_enc)
    FixtureBaseline.Car.FuelFigures.speed!(fuel_enc, UInt16(55))
    FixtureBaseline.Car.FuelFigures.mpg!(fuel_enc, Float32(49.0))
    FixtureBaseline.Car.FuelFigures.usageDescription!(fuel_enc, "Combined Cycle")
    FixtureBaseline.Car.FuelFigures.next!(fuel_enc)
    FixtureBaseline.Car.FuelFigures.speed!(fuel_enc, UInt16(75))
    FixtureBaseline.Car.FuelFigures.mpg!(fuel_enc, Float32(40.0))
    FixtureBaseline.Car.FuelFigures.usageDescription!(fuel_enc, "Highway Cycle")

    perf_enc = FixtureBaseline.Car.performanceFigures!(enc, 2)
    FixtureBaseline.Car.PerformanceFigures.next!(perf_enc)
    FixtureBaseline.Car.PerformanceFigures.octaneRating!(perf_enc, UInt8(95))
    accel_enc = FixtureBaseline.Car.PerformanceFigures.acceleration!(perf_enc, 3)
    FixtureBaseline.Car.PerformanceFigures.Acceleration.next!(accel_enc)
    FixtureBaseline.Car.PerformanceFigures.Acceleration.mph!(accel_enc, UInt16(30))
    FixtureBaseline.Car.PerformanceFigures.Acceleration.seconds!(accel_enc, Float32(4.0))
    FixtureBaseline.Car.PerformanceFigures.Acceleration.next!(accel_enc)
    FixtureBaseline.Car.PerformanceFigures.Acceleration.mph!(accel_enc, UInt16(60))
    FixtureBaseline.Car.PerformanceFigures.Acceleration.seconds!(accel_enc, Float32(7.5))
    FixtureBaseline.Car.PerformanceFigures.Acceleration.next!(accel_enc)
    FixtureBaseline.Car.PerformanceFigures.Acceleration.mph!(accel_enc, UInt16(100))
    FixtureBaseline.Car.PerformanceFigures.Acceleration.seconds!(accel_enc, Float32(12.2))

    FixtureBaseline.Car.PerformanceFigures.next!(perf_enc)
    FixtureBaseline.Car.PerformanceFigures.octaneRating!(perf_enc, UInt8(99))
    accel_enc = FixtureBaseline.Car.PerformanceFigures.acceleration!(perf_enc, 3)
    FixtureBaseline.Car.PerformanceFigures.Acceleration.next!(accel_enc)
    FixtureBaseline.Car.PerformanceFigures.Acceleration.mph!(accel_enc, UInt16(30))
    FixtureBaseline.Car.PerformanceFigures.Acceleration.seconds!(accel_enc, Float32(3.8))
    FixtureBaseline.Car.PerformanceFigures.Acceleration.next!(accel_enc)
    FixtureBaseline.Car.PerformanceFigures.Acceleration.mph!(accel_enc, UInt16(60))
    FixtureBaseline.Car.PerformanceFigures.Acceleration.seconds!(accel_enc, Float32(7.1))
    FixtureBaseline.Car.PerformanceFigures.Acceleration.next!(accel_enc)
    FixtureBaseline.Car.PerformanceFigures.Acceleration.mph!(accel_enc, UInt16(100))
    FixtureBaseline.Car.PerformanceFigures.Acceleration.seconds!(accel_enc, Float32(11.8))

    FixtureBaseline.Car.manufacturer!(enc, "Honda")
    FixtureBaseline.Car.model!(enc, "Civic VTi")
    FixtureBaseline.Car.activationCode!(enc, "abcdef")

    header_len = Int(FixtureBaseline.MessageHeader.sbe_encoded_length(FixtureBaseline.MessageHeader.Decoder))
    encoded_len = FixtureBaseline.Car.sbe_encoded_length(enc)
    total_len = header_len + encoded_len
    @test total_len == length(bytes)
    @test buffer[1:total_len] == bytes
end
