using Test
using SBE

module JsonPrinterGenerated
    include(joinpath(@__DIR__, "generated", "JsonPrinterBaseline.jl"))
    using .Baseline
end

const JBaseline = JsonPrinterGenerated.Baseline

function encode_test_message(buffer::AbstractVector{UInt8})
    enc = JBaseline.Car.Encoder(buffer, 0)

    JBaseline.Car.serialNumber!(enc, UInt64(1234))
    JBaseline.Car.modelYear!(enc, UInt16(2013))
    JBaseline.Car.available!(enc, JBaseline.BooleanType.T)
    JBaseline.Car.code!(enc, JBaseline.Model.A)
    JBaseline.Car.vehicleCode!(enc, "ab\"def")

    nums = JBaseline.Car.someNumbers!(enc)
    for i in 1:length(nums)
        nums[i] = UInt32(i - 1)
    end

    extras = JBaseline.Car.extras(enc)
    JBaseline.OptionalExtras.cruiseControl!(extras, true)
    JBaseline.OptionalExtras.sportsPack!(extras, true)
    JBaseline.OptionalExtras.sunRoof!(extras, false)

    engine = JBaseline.Car.engine(enc)
    JBaseline.Engine.capacity!(engine, UInt16(2000))
    JBaseline.Engine.numCylinders!(engine, UInt8(4))
    JBaseline.Engine.manufacturerCode!(engine, "123")

    uuid = JBaseline.Car.uuid!(enc)
    uuid[1] = Int64(7)
    uuid[2] = Int64(3)
    JBaseline.Car.cupHolderCount!(enc, UInt8(5))

    fuel = JBaseline.Car.fuelFigures!(enc, 3)
    JBaseline.Car.FuelFigures.next!(fuel)
    JBaseline.Car.FuelFigures.speed!(fuel, UInt16(30))
    JBaseline.Car.FuelFigures.mpg!(fuel, Float32(35.9))
    JBaseline.Car.FuelFigures.next!(fuel)
    JBaseline.Car.FuelFigures.speed!(fuel, UInt16(55))
    JBaseline.Car.FuelFigures.mpg!(fuel, Float32(49.0))
    JBaseline.Car.FuelFigures.next!(fuel)
    JBaseline.Car.FuelFigures.speed!(fuel, UInt16(75))
    JBaseline.Car.FuelFigures.mpg!(fuel, Float32(40.0))

    perf = JBaseline.Car.performanceFigures!(enc, 2)
    JBaseline.Car.PerformanceFigures.next!(perf)
    JBaseline.Car.PerformanceFigures.octaneRating!(perf, UInt8(95))
    accel = JBaseline.Car.PerformanceFigures.acceleration!(perf, 3)
    JBaseline.Car.PerformanceFigures.Acceleration.next!(accel)
    JBaseline.Car.PerformanceFigures.Acceleration.mph!(accel, UInt16(30))
    JBaseline.Car.PerformanceFigures.Acceleration.seconds!(accel, Float32(4.0))
    JBaseline.Car.PerformanceFigures.Acceleration.next!(accel)
    JBaseline.Car.PerformanceFigures.Acceleration.mph!(accel, UInt16(60))
    JBaseline.Car.PerformanceFigures.Acceleration.seconds!(accel, Float32(7.5))
    JBaseline.Car.PerformanceFigures.Acceleration.next!(accel)
    JBaseline.Car.PerformanceFigures.Acceleration.mph!(accel, UInt16(100))
    JBaseline.Car.PerformanceFigures.Acceleration.seconds!(accel, Float32(12.2))

    JBaseline.Car.PerformanceFigures.next!(perf)
    JBaseline.Car.PerformanceFigures.octaneRating!(perf, UInt8(99))
    accel = JBaseline.Car.PerformanceFigures.acceleration!(perf, 3)
    JBaseline.Car.PerformanceFigures.Acceleration.next!(accel)
    JBaseline.Car.PerformanceFigures.Acceleration.mph!(accel, UInt16(30))
    JBaseline.Car.PerformanceFigures.Acceleration.seconds!(accel, Float32(3.8))
    JBaseline.Car.PerformanceFigures.Acceleration.next!(accel)
    JBaseline.Car.PerformanceFigures.Acceleration.mph!(accel, UInt16(60))
    JBaseline.Car.PerformanceFigures.Acceleration.seconds!(accel, Float32(7.1))
    JBaseline.Car.PerformanceFigures.Acceleration.next!(accel)
    JBaseline.Car.PerformanceFigures.Acceleration.mph!(accel, UInt16(100))
    JBaseline.Car.PerformanceFigures.Acceleration.seconds!(accel, Float32(11.8))

    JBaseline.Car.manufacturer!(enc, "Honda")
    JBaseline.Car.model!(enc, "Civic VTi")
    JBaseline.Car.activationCode!(enc, "315\\8")

    return JBaseline.Car.sbe_encoded_length(enc)
end

function get_values(dec)
    values = Any[]
    push!(values, JBaseline.Car.serialNumber(dec))
    push!(values, JBaseline.Car.modelYear(dec))
    push!(values, JBaseline.Car.available(dec))
    push!(values, JBaseline.Car.code(dec))

    numbers = JBaseline.Car.someNumbers(dec)
    push!(values, length(numbers))
    append!(values, collect(numbers))

    push!(values, String(JBaseline.Car.vehicleCode(dec)))

    extras = JBaseline.Car.extras(dec)
    push!(values, JBaseline.OptionalExtras.sunRoof(extras))
    push!(values, JBaseline.OptionalExtras.sportsPack(extras))
    push!(values, JBaseline.OptionalExtras.cruiseControl(extras))

    engine = JBaseline.Car.engine(dec)
    push!(values, JBaseline.Engine.capacity(engine))
    push!(values, JBaseline.Engine.numCylinders(engine))
    push!(values, JBaseline.Engine.maxRpm(engine))
    push!(values, String(JBaseline.Engine.manufacturerCode(engine)))
    push!(values, String(JBaseline.Engine.fuel(engine)))

    fuel = JBaseline.Car.fuelFigures(dec)
    for group in fuel
        push!(values, JBaseline.Car.FuelFigures.speed(group))
        push!(values, JBaseline.Car.FuelFigures.mpg(group))
    end

    perf = JBaseline.Car.performanceFigures(dec)
    for group in perf
        push!(values, JBaseline.Car.PerformanceFigures.octaneRating(group))
        accel = JBaseline.Car.PerformanceFigures.acceleration(group)
        for acc in accel
            push!(values, JBaseline.Car.PerformanceFigures.Acceleration.mph(acc))
            push!(values, JBaseline.Car.PerformanceFigures.Acceleration.seconds(acc))
        end
    end

    push!(values, String(JBaseline.Car.manufacturer(dec)))
    push!(values, String(JBaseline.Car.model(dec)))
    push!(values, String(JBaseline.Car.activationCode(dec)))

    return values
end

function get_partial_values(dec)
    values = Any[]
    push!(values, JBaseline.Car.serialNumber(dec))
    push!(values, JBaseline.Car.modelYear(dec))
    push!(values, JBaseline.Car.available(dec))
    push!(values, JBaseline.Car.code(dec))

    numbers = JBaseline.Car.someNumbers(dec)
    push!(values, length(numbers))
    append!(values, collect(numbers))

    push!(values, String(JBaseline.Car.vehicleCode(dec)))

    extras = JBaseline.Car.extras(dec)
    push!(values, JBaseline.OptionalExtras.sunRoof(extras))
    push!(values, JBaseline.OptionalExtras.sportsPack(extras))
    push!(values, JBaseline.OptionalExtras.cruiseControl(extras))

    engine = JBaseline.Car.engine(dec)
    push!(values, JBaseline.Engine.capacity(engine))
    push!(values, JBaseline.Engine.numCylinders(engine))
    push!(values, JBaseline.Engine.maxRpm(engine))
    push!(values, String(JBaseline.Engine.manufacturerCode(engine)))
    push!(values, String(JBaseline.Engine.fuel(engine)))

    fuel = JBaseline.Car.fuelFigures(dec)
    for group in fuel
        push!(values, JBaseline.Car.FuelFigures.speed(group))
        push!(values, JBaseline.Car.FuelFigures.mpg(group))
    end

    perf = JBaseline.Car.performanceFigures(dec)
    if length(perf) > 0
        JBaseline.Car.PerformanceFigures.next!(perf)
        push!(values, JBaseline.Car.PerformanceFigures.octaneRating(perf))
        accel = JBaseline.Car.PerformanceFigures.acceleration(perf)
        if length(accel) > 0
            JBaseline.Car.PerformanceFigures.Acceleration.next!(accel)
            push!(values, JBaseline.Car.PerformanceFigures.Acceleration.mph(accel))
        end
    end

    return values
end

@testset "Java Mirror Tests" begin
    @testset "Rewind" begin
        buffer = zeros(UInt8, 4096)
        encode_test_message(buffer)
        dec = JBaseline.Car.Decoder(buffer, 0)

        pass_one = get_values(dec)
        JBaseline.Car.sbe_rewind!(dec)
        pass_two = get_values(dec)
        @test pass_one == pass_two

        JBaseline.Car.sbe_rewind!(dec)
        partial_one = get_partial_values(dec)
        JBaseline.Car.sbe_rewind!(dec)
        partial_two = get_partial_values(dec)
        @test pass_one != partial_one
        @test partial_one == partial_two

        JBaseline.Car.sbe_rewind!(dec)
        pass_three = get_values(dec)
        @test pass_one == pass_three
    end

    @testset "SkipAndDecodedLength" begin
        buffer = zeros(UInt8, 4096)
        encoded_length = encode_test_message(buffer)
        dec = JBaseline.Car.Decoder(buffer, 0)

        decoded_length_no_read = JBaseline.Car.sbe_decoded_length(dec)

        initial_pos = SBE.sbe_position(dec)
        get_values(dec)
        read_pos = SBE.sbe_position(dec)

        JBaseline.Car.sbe_rewind!(dec)
        rewind_pos = SBE.sbe_position(dec)
        JBaseline.Car.sbe_skip!(dec)
        skip_pos = SBE.sbe_position(dec)

        decoded_length_full_skip = JBaseline.Car.sbe_decoded_length(dec)
        JBaseline.Car.sbe_rewind!(dec)
        decoded_length_after_rewind = JBaseline.Car.sbe_decoded_length(dec)
        JBaseline.Car.sbe_rewind!(dec)
        get_partial_values(dec)
        decoded_length_partial = JBaseline.Car.sbe_decoded_length(dec)

        @test rewind_pos == initial_pos
        @test skip_pos == read_pos
        @test decoded_length_no_read == encoded_length
        @test decoded_length_full_skip == encoded_length
        @test decoded_length_after_rewind == encoded_length
        @test decoded_length_partial == encoded_length
    end
end
