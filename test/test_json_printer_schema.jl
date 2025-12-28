using Test

@testset "Json Printer Schema" begin
    buffer = zeros(UInt8, 512)
    header = JsonPrinterSchema.MessageHeader.Encoder(buffer, 0)
    enc = JsonPrinterSchema.Car.Encoder(typeof(buffer))
    JsonPrinterSchema.Car.wrap_and_apply_header!(enc, buffer, 0; header=header)

    JsonPrinterSchema.Car.serialNumber!(enc, UInt64(123))
    JsonPrinterSchema.Car.modelYear!(enc, UInt16(2024))
    JsonPrinterSchema.Car.available!(enc, JsonPrinterSchema.BooleanType.T)
    JsonPrinterSchema.Car.code!(enc, JsonPrinterSchema.Model.A)
    JsonPrinterSchema.Car.vehicleCode!(enc, "EV2024")

    engine = JsonPrinterSchema.Car.engine(enc)
    JsonPrinterSchema.Engine.capacity!(engine, UInt16(1600))
    JsonPrinterSchema.Engine.numCylinders!(engine, UInt8(4))

    JsonPrinterSchema.Car.uuid!(enc, [Int64(1), Int64(2)])
    JsonPrinterSchema.Car.cupHolderCount!(enc, UInt8(2))

    JsonPrinterSchema.Car.manufacturer!(enc, "Tesla")
    JsonPrinterSchema.Car.model!(enc, "Model3")

    dec = JsonPrinterSchema.Car.Decoder(typeof(buffer))
    JsonPrinterSchema.Car.wrap!(dec, buffer, 0)
    @test JsonPrinterSchema.Car.serialNumber(dec) == UInt64(123)
    @test JsonPrinterSchema.Car.modelYear(dec) == UInt16(2024)
    @test JsonPrinterSchema.Car.available(dec) == JsonPrinterSchema.BooleanType.T
    @test JsonPrinterSchema.Car.code(dec) == JsonPrinterSchema.Model.A
    @test String(JsonPrinterSchema.Car.vehicleCode(dec)) == "EV2024"
    @test JsonPrinterSchema.Engine.capacity(JsonPrinterSchema.Car.engine(dec)) == UInt16(1600)
    @test JsonPrinterSchema.Engine.numCylinders(JsonPrinterSchema.Car.engine(dec)) == UInt8(4)
    @test collect(JsonPrinterSchema.Car.uuid(dec)) == Int64[1, 2]
    @test JsonPrinterSchema.Car.cupHolderCount(dec) == UInt8(2)
    @test String(JsonPrinterSchema.Car.manufacturer(dec)) == "Tesla"
    @test String(JsonPrinterSchema.Car.model(dec)) == "Model3"

    creds_buffer = zeros(UInt8, 128)
    creds_header = JsonPrinterSchema.MessageHeader.Encoder(creds_buffer, 0)
    creds_enc = JsonPrinterSchema.Credentials.Encoder(typeof(creds_buffer))
    JsonPrinterSchema.Credentials.wrap_and_apply_header!(creds_enc, creds_buffer, 0; header=creds_header)
    JsonPrinterSchema.Credentials.login!(creds_enc, "user")
    JsonPrinterSchema.Credentials.encryptedPassword!(creds_enc, UInt8[0xAA, 0xBB])

    creds_dec = JsonPrinterSchema.Credentials.Decoder(typeof(creds_buffer))
    JsonPrinterSchema.Credentials.wrap!(creds_dec, creds_buffer, 0)
    @test String(JsonPrinterSchema.Credentials.login(creds_dec)) == "user"
    @test collect(JsonPrinterSchema.Credentials.encryptedPassword(creds_dec)) == UInt8[0xAA, 0xBB]
end
