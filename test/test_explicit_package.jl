using Test

@testset "Explicit Package Types" begin
    buffer = zeros(UInt8, 128)
    header = ExplicitPackage.MessageHeader.Encoder(buffer, 0)
    enc = ExplicitPackage.TestMessage.Encoder(buffer, 0; header=header)

    ExplicitPackage.TestMessage.id!(enc, UInt64(42))
    car_enc = ExplicitPackage.TestMessage.car(enc)
    ExplicitPackage.Car.make!(car_enc, UInt16(7))
    ExplicitPackage.Car.model!(car_enc, UInt16(9))
    ExplicitPackage.Car.vintage!(car_enc, ExplicitPackage.BooleanType.TRUE)
    engine_enc = ExplicitPackage.Car.engine(car_enc)
    ExplicitPackage.Engine.power!(engine_enc, Int32(120))
    ExplicitPackage.Engine.torque!(engine_enc, Int32(240))
    ExplicitPackage.Engine.ice!(engine_enc, ExplicitPackage.BooleanType.FALSE)
    fuel_enc = ExplicitPackage.Engine.fuel(engine_enc)
    ExplicitPackage.FuelSpec.limit!(fuel_enc, Int32(10))
    fuel_set = ExplicitPackage.FuelSpec.fuel(fuel_enc)
    ExplicitPackage.FuelType.Diesel!(fuel_set, true)

    ExplicitPackage.TestMessage.electric!(enc, ExplicitPackage.BooleanType.TRUE)
    days_enc = ExplicitPackage.TestMessage.toChargeOn(enc)
    ExplicitPackage.Days.Monday!(days_enc, true)
    ExplicitPackage.Days.Friday!(days_enc, true)

    dec = ExplicitPackage.TestMessage.Decoder(buffer, 0)
    @test ExplicitPackage.TestMessage.id(dec) == UInt64(42)
    car_dec = ExplicitPackage.TestMessage.car(dec)
    @test ExplicitPackage.Car.make(car_dec) == UInt16(7)
    @test ExplicitPackage.Car.model(car_dec) == UInt16(9)
    @test ExplicitPackage.Car.vintage(car_dec) == ExplicitPackage.BooleanType.TRUE
    engine_dec = ExplicitPackage.Car.engine(car_dec)
    @test ExplicitPackage.Engine.power(engine_dec) == Int32(120)
    @test ExplicitPackage.Engine.torque(engine_dec) == Int32(240)
    @test ExplicitPackage.Engine.ice(engine_dec) == ExplicitPackage.BooleanType.FALSE
    fuel_dec = ExplicitPackage.Engine.fuel(engine_dec)
    @test ExplicitPackage.FuelSpec.limit(fuel_dec) == Int32(10)
    fuel_set_dec = ExplicitPackage.FuelSpec.fuel(fuel_dec)
    @test ExplicitPackage.FuelType.Diesel(fuel_set_dec)

    @test ExplicitPackage.TestMessage.electric(dec) == ExplicitPackage.BooleanType.TRUE
    days_dec = ExplicitPackage.TestMessage.toChargeOn(dec)
    @test ExplicitPackage.Days.Monday(days_dec)
    @test ExplicitPackage.Days.Friday(days_dec)
end
