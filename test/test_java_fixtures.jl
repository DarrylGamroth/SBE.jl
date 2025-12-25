using Test
using SBE

module FixtureGenerated
    include(joinpath(@__DIR__, "generated", "Baseline.jl"))
    using .Baseline
end

const FixtureBaseline = FixtureGenerated.Baseline

function encode_baseline_car!(buffer::Vector{UInt8})
    header = FixtureBaseline.MessageHeader.Encoder(buffer, 0)
    enc = FixtureBaseline.Car.Encoder(buffer, 0; header=header)

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
    return header_len + encoded_len
end

@testset "Java Codegen Keyword Fixture Parity" begin
    fixture_path = joinpath(@__DIR__, "java-fixtures", "codegen-global-keywords.bin")
    @test isfile(fixture_path)
    bytes = read(fixture_path)

    dec = CodeGenerationTest.GlobalKeywords.Decoder(bytes, 0)
    @test CodeGenerationTest.GlobalKeywords.abstract_(dec) == Int8(1)
    @test CodeGenerationTest.GlobalKeywords.break_(dec) == Int8(2)
    @test CodeGenerationTest.GlobalKeywords.const_(dec) == Int8(3)
    @test CodeGenerationTest.GlobalKeywords.continue_(dec) == Int8(4)
    @test CodeGenerationTest.GlobalKeywords.do_(dec) == Int8(5)
    @test CodeGenerationTest.GlobalKeywords.else_(dec) == Int8(6)
    @test CodeGenerationTest.GlobalKeywords.for_(dec) == Int8(7)
    @test CodeGenerationTest.GlobalKeywords.if_(dec) == Int8(8)
    @test CodeGenerationTest.GlobalKeywords.false_(dec) == Int8(9)
    @test CodeGenerationTest.GlobalKeywords.try_(dec) == Int8(10)
    @test CodeGenerationTest.GlobalKeywords.struct_(dec) == Int8(11)
    @test CodeGenerationTest.GlobalKeywords.new_(dec) == Int8(12)
    @test String(CodeGenerationTest.GlobalKeywords.import_(dec)) == "IMPORT"
    @test String(CodeGenerationTest.GlobalKeywords.strictfp(dec)) == "STRICTFP"

    data_group = CodeGenerationTest.GlobalKeywords.data(dec)
    @test length(data_group) == 0

    @test String(CodeGenerationTest.GlobalKeywords.go(dec)) == "go-value"
    @test String(CodeGenerationTest.GlobalKeywords.package(dec)) == "package-value"
    @test String(CodeGenerationTest.GlobalKeywords.var(dec)) == "var-value"

    buffer = zeros(UInt8, 4096)
    enc = CodeGenerationTest.GlobalKeywords.Encoder(buffer, 0)
    CodeGenerationTest.GlobalKeywords.abstract_!(enc, Int8(1))
    CodeGenerationTest.GlobalKeywords.break_!(enc, Int8(2))
    CodeGenerationTest.GlobalKeywords.const_!(enc, Int8(3))
    CodeGenerationTest.GlobalKeywords.continue_!(enc, Int8(4))
    CodeGenerationTest.GlobalKeywords.do_!(enc, Int8(5))
    CodeGenerationTest.GlobalKeywords.else_!(enc, Int8(6))
    CodeGenerationTest.GlobalKeywords.for_!(enc, Int8(7))
    CodeGenerationTest.GlobalKeywords.if_!(enc, Int8(8))
    CodeGenerationTest.GlobalKeywords.false_!(enc, Int8(9))
    CodeGenerationTest.GlobalKeywords.try_!(enc, Int8(10))
    CodeGenerationTest.GlobalKeywords.struct_!(enc, Int8(11))
    CodeGenerationTest.GlobalKeywords.new_!(enc, Int8(12))
    CodeGenerationTest.GlobalKeywords.import_!(enc, "IMPORT")
    CodeGenerationTest.GlobalKeywords.strictfp!(enc, "STRICTFP")

    CodeGenerationTest.GlobalKeywords.data!(enc, 0)
    CodeGenerationTest.GlobalKeywords.go!(enc, "go-value")
    CodeGenerationTest.GlobalKeywords.package!(enc, "package-value")
    CodeGenerationTest.GlobalKeywords.var!(enc, "var-value")

    header_len = Int(CodeGenerationTest.MessageHeader.sbe_encoded_length(CodeGenerationTest.MessageHeader.Decoder))
    total_len = header_len + CodeGenerationTest.GlobalKeywords.sbe_encoded_length(enc)
    @test total_len == length(bytes)
    @test buffer[1:total_len] == bytes
end

@testset "Java Extension Fixture Parity" begin
    fixture_path = joinpath(@__DIR__, "java-fixtures", "car-extension.bin")
    @test isfile(fixture_path)
    bytes = read(fixture_path)

    dec = Extension.Car.Decoder(bytes, 0)

    @test Extension.Car.serialNumber(dec) == UInt64(1234)
    @test Extension.Car.modelYear(dec) == UInt16(2013)
    @test Extension.Car.available(dec) == Extension.BooleanType.T
    @test Extension.Car.code(dec) == Extension.Model.A

    uuid = Extension.Car.uuid(dec)
    @test uuid[1] == Int64(7)
    @test uuid[2] == Int64(3)
    @test Extension.Car.cupHolderCount(dec) == UInt8(5)

    fuel = Extension.Car.fuelFigures(dec)
    Extension.Car.FuelFigures.next!(fuel)
    Extension.Car.FuelFigures.usageDescription(fuel)
    Extension.Car.FuelFigures.next!(fuel)
    Extension.Car.FuelFigures.usageDescription(fuel)
    Extension.Car.FuelFigures.next!(fuel)
    Extension.Car.FuelFigures.usageDescription(fuel)

    perf = Extension.Car.performanceFigures(dec)
    Extension.Car.PerformanceFigures.next!(perf)
    accel = Extension.Car.PerformanceFigures.acceleration(perf)
    Extension.Car.PerformanceFigures.Acceleration.next!(accel)
    Extension.Car.PerformanceFigures.Acceleration.seconds(accel)
    Extension.Car.PerformanceFigures.Acceleration.next!(accel)
    Extension.Car.PerformanceFigures.Acceleration.seconds(accel)
    Extension.Car.PerformanceFigures.Acceleration.next!(accel)
    Extension.Car.PerformanceFigures.Acceleration.seconds(accel)

    Extension.Car.PerformanceFigures.next!(perf)
    accel = Extension.Car.PerformanceFigures.acceleration(perf)
    Extension.Car.PerformanceFigures.Acceleration.next!(accel)
    Extension.Car.PerformanceFigures.Acceleration.seconds(accel)
    Extension.Car.PerformanceFigures.Acceleration.next!(accel)
    Extension.Car.PerformanceFigures.Acceleration.seconds(accel)
    Extension.Car.PerformanceFigures.Acceleration.next!(accel)
    Extension.Car.PerformanceFigures.Acceleration.seconds(accel)

    @test String(Extension.Car.manufacturer(dec)) == "Honda"
    @test String(Extension.Car.model(dec)) == "Civic VTi"
    @test String(Extension.Car.activationCode(dec)) == "abcdef"

    buffer = zeros(UInt8, 4096)
    enc = Extension.Car.Encoder(buffer, 0)

    Extension.Car.serialNumber!(enc, UInt64(1234))
    Extension.Car.modelYear!(enc, UInt16(2013))
    Extension.Car.available!(enc, Extension.BooleanType.T)
    Extension.Car.code!(enc, Extension.Model.A)

    nums = Extension.Car.someNumbers!(enc)
    nums[1] = UInt32(1)
    nums[2] = UInt32(2)
    nums[3] = UInt32(3)
    nums[4] = UInt32(4)

    Extension.Car.vehicleCode!(enc, "abcdef")

    extras_enc = Extension.Car.extras(enc)
    Extension.OptionalExtras.cruiseControl!(extras_enc, true)
    Extension.OptionalExtras.sportsPack!(extras_enc, true)
    Extension.OptionalExtras.sunRoof!(extras_enc, false)

    engine_enc = Extension.Car.engine(enc)
    Extension.Engine.capacity!(engine_enc, UInt16(2000))
    Extension.Engine.numCylinders!(engine_enc, UInt8(4))
    Extension.Engine.manufacturerCode!(engine_enc, "123")
    Extension.Engine.efficiency!(engine_enc, Int8(35))
    Extension.Engine.boosterEnabled!(engine_enc, Extension.BooleanType.T)

    booster_enc = Extension.Engine.booster(engine_enc)
    Extension.Booster.boostType!(booster_enc, Extension.Booster.BoostType.NITROUS)
    Extension.Booster.horsePower!(booster_enc, UInt8(200))

    uuid_enc = Extension.Car.uuid!(enc)
    uuid_enc[1] = Int64(7)
    uuid_enc[2] = Int64(3)
    Extension.Car.cupHolderCount!(enc, UInt8(5))

    fuel_enc = Extension.Car.fuelFigures!(enc, 3)
    Extension.Car.FuelFigures.next!(fuel_enc)
    Extension.Car.FuelFigures.speed!(fuel_enc, UInt16(30))
    Extension.Car.FuelFigures.mpg!(fuel_enc, Float32(35.9))
    Extension.Car.FuelFigures.usageDescription!(fuel_enc, "Urban Cycle")
    Extension.Car.FuelFigures.next!(fuel_enc)
    Extension.Car.FuelFigures.speed!(fuel_enc, UInt16(55))
    Extension.Car.FuelFigures.mpg!(fuel_enc, Float32(49.0))
    Extension.Car.FuelFigures.usageDescription!(fuel_enc, "Combined Cycle")
    Extension.Car.FuelFigures.next!(fuel_enc)
    Extension.Car.FuelFigures.speed!(fuel_enc, UInt16(75))
    Extension.Car.FuelFigures.mpg!(fuel_enc, Float32(40.0))
    Extension.Car.FuelFigures.usageDescription!(fuel_enc, "Highway Cycle")

    perf_enc = Extension.Car.performanceFigures!(enc, 2)
    Extension.Car.PerformanceFigures.next!(perf_enc)
    Extension.Car.PerformanceFigures.octaneRating!(perf_enc, UInt8(95))
    accel_enc = Extension.Car.PerformanceFigures.acceleration!(perf_enc, 3)
    Extension.Car.PerformanceFigures.Acceleration.next!(accel_enc)
    Extension.Car.PerformanceFigures.Acceleration.mph!(accel_enc, UInt16(30))
    Extension.Car.PerformanceFigures.Acceleration.seconds!(accel_enc, Float32(4.0))
    Extension.Car.PerformanceFigures.Acceleration.next!(accel_enc)
    Extension.Car.PerformanceFigures.Acceleration.mph!(accel_enc, UInt16(60))
    Extension.Car.PerformanceFigures.Acceleration.seconds!(accel_enc, Float32(7.5))
    Extension.Car.PerformanceFigures.Acceleration.next!(accel_enc)
    Extension.Car.PerformanceFigures.Acceleration.mph!(accel_enc, UInt16(100))
    Extension.Car.PerformanceFigures.Acceleration.seconds!(accel_enc, Float32(12.2))

    Extension.Car.PerformanceFigures.next!(perf_enc)
    Extension.Car.PerformanceFigures.octaneRating!(perf_enc, UInt8(99))
    accel_enc = Extension.Car.PerformanceFigures.acceleration!(perf_enc, 3)
    Extension.Car.PerformanceFigures.Acceleration.next!(accel_enc)
    Extension.Car.PerformanceFigures.Acceleration.mph!(accel_enc, UInt16(30))
    Extension.Car.PerformanceFigures.Acceleration.seconds!(accel_enc, Float32(3.8))
    Extension.Car.PerformanceFigures.Acceleration.next!(accel_enc)
    Extension.Car.PerformanceFigures.Acceleration.mph!(accel_enc, UInt16(60))
    Extension.Car.PerformanceFigures.Acceleration.seconds!(accel_enc, Float32(7.1))
    Extension.Car.PerformanceFigures.Acceleration.next!(accel_enc)
    Extension.Car.PerformanceFigures.Acceleration.mph!(accel_enc, UInt16(100))
    Extension.Car.PerformanceFigures.Acceleration.seconds!(accel_enc, Float32(11.8))

    Extension.Car.manufacturer!(enc, "Honda")
    Extension.Car.model!(enc, "Civic VTi")
    Extension.Car.activationCode!(enc, "abcdef")

    header_len = Int(Extension.MessageHeader.sbe_encoded_length(Extension.MessageHeader.Decoder))
    total_len = header_len + Extension.Car.sbe_encoded_length(enc)
    @test total_len == length(bytes)
    @test buffer[1:total_len] == bytes
end

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
    total_len = encode_baseline_car!(buffer)
    @test total_len == length(bytes)
    @test buffer[1:total_len] == bytes
end

@testset "Java Decoder Round-Trip (Julia -> Java)" begin
    sbe_version = get(ENV, "SBE_VERSION", "1.36.2")
    jar_default = joinpath(homedir(), ".cache", "sbe", "sbe-all-$(sbe_version).jar")
    jar_path = get(ENV, "SBE_JAR_PATH", jar_default)
    class_dir = joinpath(@__DIR__, "java-fixtures", "classes")
    java = Sys.which("java")
    java_opts = ["--add-opens=java.base/jdk.internal.misc=ALL-UNNAMED"]
    classpath_sep = Sys.iswindows() ? ";" : ":"

    if java === nothing || !isfile(jar_path) || !isdir(class_dir)
        reason = "Skipping Java round-trip: missing java=$(java === nothing ? "not found" : java), " *
                 "SBE_JAR_PATH=$(isfile(jar_path) ? "found" : "missing"), " *
                 "classes=$(isdir(class_dir) ? "found" : "missing")"
        @test_skip reason
        return
    end

    buffer = zeros(UInt8, 4096)
    total_len = encode_baseline_car!(buffer)

    mktemp() do path, io
        write(io, buffer[1:total_len])
        close(io)
        run(`$java $(java_opts...) -cp $jar_path$classpath_sep$class_dir VerifyCarFixture $path`)
    end
end
