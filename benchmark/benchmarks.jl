using BenchmarkTools
import Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using SBE

const SCHEMA_PATH = joinpath(@__DIR__, "..", "test", "example-schema.xml")
const MODULE_NAME = SBE.@load_schema SCHEMA_PATH
const Baseline = getfield(Main, MODULE_NAME)

const BUFFER_SIZE = 4096
const ENCODE_BUFFER = zeros(UInt8, BUFFER_SIZE)
const DECODE_BUFFER = zeros(UInt8, BUFFER_SIZE)

const VEHICLE_BYTES = Vector{UInt8}(codeunits("ABC123"))
const MANUF_BYTES = Vector{UInt8}(codeunits("Honda"))
const MODEL_BYTES = Vector{UInt8}(codeunits("Civic"))
const ACTIVATION_BYTES = Vector{UInt8}(codeunits("ABCD1234"))
const XYZ_BYTES = Vector{UInt8}(codeunits("XYZ"))
const SOME_NUMBERS = UInt32[1, 2, 3, 4]

const SINK = Ref{UInt64}(0)

function encode_car_construct!(buffer::AbstractVector{UInt8})
    enc = Baseline.Car.Encoder(typeof(buffer))
    Baseline.Car.wrap_and_apply_header!(enc, buffer, 0)

    Baseline.Car.serialNumber!(enc, UInt64(12345))
    Baseline.Car.modelYear!(enc, UInt16(2024))
    Baseline.Car.available!(enc, Baseline.BooleanType.T)
    Baseline.Car.code!(enc, Baseline.Model.A)

    vehicle_dest = Baseline.Car.vehicleCode!(enc)
    copyto!(vehicle_dest, VEHICLE_BYTES)
    numbers_dest = Baseline.Car.someNumbers!(enc)
    copyto!(numbers_dest, SOME_NUMBERS)

    engine = Baseline.Car.engine(enc)
    Baseline.Engine.capacity!(engine, UInt16(2000))
    Baseline.Engine.numCylinders!(engine, UInt8(4))
    engine_code_dest = Baseline.Engine.manufacturerCode!(engine)
    copyto!(engine_code_dest, XYZ_BYTES)

    extras = Baseline.Car.extras(enc)
    Baseline.OptionalExtras.sunRoof!(extras, true)
    Baseline.OptionalExtras.cruiseControl!(extras, true)

    fuel = Baseline.Car.fuelFigures!(enc, 2)
    Baseline.Car.FuelFigures.next!(fuel)
    Baseline.Car.FuelFigures.speed!(fuel, UInt16(30))
    Baseline.Car.FuelFigures.mpg!(fuel, Float32(35.9))
    Baseline.Car.FuelFigures.next!(fuel)
    Baseline.Car.FuelFigures.speed!(fuel, UInt16(70))
    Baseline.Car.FuelFigures.mpg!(fuel, Float32(49.0))

    perf = Baseline.Car.performanceFigures!(enc, 1)
    Baseline.Car.PerformanceFigures.next!(perf)
    Baseline.Car.PerformanceFigures.octaneRating!(perf, UInt8(95))
    accel = Baseline.Car.PerformanceFigures.acceleration!(perf, 1)
    Baseline.Car.PerformanceFigures.Acceleration.next!(accel)
    Baseline.Car.PerformanceFigures.Acceleration.mph!(accel, UInt16(60))
    Baseline.Car.PerformanceFigures.Acceleration.seconds!(accel, Float32(4.5))

    Baseline.Car.manufacturer!(enc, MANUF_BYTES)
    Baseline.Car.model!(enc, MODEL_BYTES)
    Baseline.Car.activationCode!(enc, ACTIVATION_BYTES)

    return enc
end

mutable struct EncodeWrapCtx{E,H,EN,EX,EC,VD,ND,FG,PF,AC}
    buffer::Vector{UInt8}
    position_ptr::PositionPointer
    enc::E
    header::H
    engine::EN
    extras::EX
    engine_code_dest::EC
    vehicle_dest::VD
    numbers_dest::ND
    fuel::FG
    perf::PF
    accel::AC
end

function build_encode_wrap_ctx(buffer::Vector{UInt8})
    header = Baseline.MessageHeader.Encoder(buffer, 0)
    enc = Baseline.Car.Encoder(typeof(buffer))
    Baseline.Car.wrap_and_apply_header!(enc, buffer, 0; header=header)
    position_ptr = enc.position_ptr

    engine = Baseline.Car.engine(enc)
    extras = Baseline.Car.extras(enc)

    engine_code_dest = Baseline.Engine.manufacturerCode!(engine)
    vehicle_dest = Baseline.Car.vehicleCode!(enc)
    numbers_dest = Baseline.Car.someNumbers!(enc)

    fuel = Baseline.Car.FuelFigures.Encoder(buffer, 0, position_ptr, 0, 0, 0)
    perf = Baseline.Car.PerformanceFigures.Encoder(buffer, 0, position_ptr, 0, 0, 0)
    accel = Baseline.Car.PerformanceFigures.Acceleration.Encoder(buffer, 0, position_ptr, 0, 0, 0)

    return EncodeWrapCtx(
        buffer,
        position_ptr,
        enc,
        header,
        engine,
        extras,
        engine_code_dest,
        vehicle_dest,
        numbers_dest,
        fuel,
        perf,
        accel,
    )
end

function encode_car_wrap!(ctx::EncodeWrapCtx)
    Baseline.Car.wrap_and_apply_header!(ctx.enc, ctx.buffer, 0; header=ctx.header)

    enc = ctx.enc
    Baseline.Car.serialNumber!(enc, UInt64(12345))
    Baseline.Car.modelYear!(enc, UInt16(2024))
    Baseline.Car.available!(enc, Baseline.BooleanType.T)
    Baseline.Car.code!(enc, Baseline.Model.A)

    copyto!(ctx.vehicle_dest, VEHICLE_BYTES)
    copyto!(ctx.numbers_dest, SOME_NUMBERS)

    engine = ctx.engine
    Baseline.Engine.capacity!(engine, UInt16(2000))
    Baseline.Engine.numCylinders!(engine, UInt8(4))
    copyto!(ctx.engine_code_dest, XYZ_BYTES)

    extras = ctx.extras
    Baseline.OptionalExtras.sunRoof!(extras, true)
    Baseline.OptionalExtras.cruiseControl!(extras, true)

    fuel = ctx.fuel
    Baseline.Car.FuelFigures.wrap!(fuel, ctx.buffer, 2, ctx.position_ptr)
    Baseline.Car.FuelFigures.next!(fuel)
    Baseline.Car.FuelFigures.speed!(fuel, UInt16(30))
    Baseline.Car.FuelFigures.mpg!(fuel, Float32(35.9))
    Baseline.Car.FuelFigures.next!(fuel)
    Baseline.Car.FuelFigures.speed!(fuel, UInt16(70))
    Baseline.Car.FuelFigures.mpg!(fuel, Float32(49.0))

    perf = ctx.perf
    Baseline.Car.PerformanceFigures.wrap!(perf, ctx.buffer, 1, ctx.position_ptr)
    Baseline.Car.PerformanceFigures.next!(perf)
    Baseline.Car.PerformanceFigures.octaneRating!(perf, UInt8(95))

    accel = ctx.accel
    Baseline.Car.PerformanceFigures.Acceleration.wrap!(accel, ctx.buffer, 1, ctx.position_ptr)
    Baseline.Car.PerformanceFigures.Acceleration.next!(accel)
    Baseline.Car.PerformanceFigures.Acceleration.mph!(accel, UInt16(60))
    Baseline.Car.PerformanceFigures.Acceleration.seconds!(accel, Float32(4.5))

    Baseline.Car.manufacturer!(enc, MANUF_BYTES)
    Baseline.Car.model!(enc, MODEL_BYTES)
    Baseline.Car.activationCode!(enc, ACTIVATION_BYTES)

    return enc
end

function decode_car_construct!(buffer::AbstractVector{UInt8})
    dec = Baseline.Car.Decoder(typeof(buffer))
    Baseline.Car.wrap!(dec, buffer, 0)

    checksum = UInt64(0)
    checksum += UInt64(Baseline.Car.serialNumber(dec))
    checksum += UInt64(Baseline.Car.modelYear(dec))
    checksum += UInt64(Baseline.Car.available(dec))
    checksum += UInt64(Baseline.Car.code(dec))
    checksum += UInt64(Baseline.Car.vehicleCode(dec)[1])
    checksum += UInt64(Baseline.Car.someNumbers(dec)[1])

    engine = Baseline.Car.engine(dec)
    checksum += UInt64(Baseline.Engine.capacity(engine))
    checksum += UInt64(Baseline.Engine.numCylinders(engine))
    checksum += UInt64(Baseline.Engine.manufacturerCode(engine)[1])

    extras = Baseline.Car.extras(dec)
    checksum += UInt64(Baseline.OptionalExtras.sunRoof(extras))
    checksum += UInt64(Baseline.OptionalExtras.cruiseControl(extras))

    speed_sum = UInt32(0)
    mpg_sum = Float32(0)
    for fig in Baseline.Car.fuelFigures(dec)
        speed_sum += Baseline.Car.FuelFigures.speed(fig)
        mpg_sum += Baseline.Car.FuelFigures.mpg(fig)
    end
    checksum += UInt64(speed_sum)
    checksum += UInt64(round(mpg_sum))

    octane_sum = Float32(0)
    for fig in Baseline.Car.performanceFigures(dec)
        octane_sum += Float32(Baseline.Car.PerformanceFigures.octaneRating(fig))
        for acc in Baseline.Car.PerformanceFigures.acceleration(fig)
            octane_sum += Float32(Baseline.Car.PerformanceFigures.Acceleration.mph(acc))
            octane_sum += Baseline.Car.PerformanceFigures.Acceleration.seconds(acc)
        end
    end
    checksum += UInt64(round(octane_sum))

    checksum += UInt64(Baseline.Car.manufacturer(dec)[1])
    checksum += UInt64(Baseline.Car.model(dec)[1])
    checksum += UInt64(Baseline.Car.activationCode(dec)[1])

    SINK[] = checksum
    return nothing
end

mutable struct DecodeWrapCtx{D,H,EN,EX,FG,PF,AC}
    buffer::Vector{UInt8}
    position_ptr::PositionPointer
    dec::D
    header::H
    engine::EN
    extras::EX
    fuel::FG
    perf::PF
    accel::AC
end

function build_decode_wrap_ctx(buffer::Vector{UInt8})
    header = Baseline.MessageHeader.Decoder(buffer, 0)
    dec = Baseline.Car.Decoder(typeof(buffer))
    Baseline.Car.wrap!(dec, buffer, 0; header=header)
    position_ptr = dec.position_ptr

    engine = Baseline.Car.engine(dec)
    extras = Baseline.Car.extras(dec)

    fuel = Baseline.Car.FuelFigures.Decoder(buffer, 0, position_ptr, 0, 0, 0, 0)
    perf = Baseline.Car.PerformanceFigures.Decoder(buffer, 0, position_ptr, 0, 0, 0, 0)
    accel = Baseline.Car.PerformanceFigures.Acceleration.Decoder(buffer, 0, position_ptr, 0, 0, 0, 0)

    return DecodeWrapCtx(
        buffer,
        position_ptr,
        dec,
        header,
        engine,
        extras,
        fuel,
        perf,
        accel,
    )
end

function decode_car_wrap!(ctx::DecodeWrapCtx)
    Baseline.Car.wrap!(ctx.dec, ctx.buffer, 0; header=ctx.header)

    dec = ctx.dec
    checksum = UInt64(0)
    checksum += UInt64(Baseline.Car.serialNumber(dec))
    checksum += UInt64(Baseline.Car.modelYear(dec))
    checksum += UInt64(Baseline.Car.available(dec))
    checksum += UInt64(Baseline.Car.code(dec))
    checksum += UInt64(Baseline.Car.vehicleCode(dec)[1])
    checksum += UInt64(Baseline.Car.someNumbers(dec)[1])

    engine = ctx.engine
    checksum += UInt64(Baseline.Engine.capacity(engine))
    checksum += UInt64(Baseline.Engine.numCylinders(engine))
    checksum += UInt64(Baseline.Engine.manufacturerCode(engine)[1])

    extras = ctx.extras
    checksum += UInt64(Baseline.OptionalExtras.sunRoof(extras))
    checksum += UInt64(Baseline.OptionalExtras.cruiseControl(extras))

    speed_sum = UInt32(0)
    mpg_sum = Float32(0)
    fuel = Baseline.Car.fuelFigures!(dec, ctx.fuel)
    for fig in fuel
        speed_sum += Baseline.Car.FuelFigures.speed(fig)
        mpg_sum += Baseline.Car.FuelFigures.mpg(fig)
    end
    checksum += UInt64(speed_sum)
    checksum += UInt64(round(mpg_sum))

    octane_sum = Float32(0)
    perf = Baseline.Car.performanceFigures!(dec, ctx.perf)
    for fig in perf
        octane_sum += Float32(Baseline.Car.PerformanceFigures.octaneRating(fig))
        accel = Baseline.Car.PerformanceFigures.acceleration!(fig, ctx.accel)
        for acc in accel
            octane_sum += Float32(Baseline.Car.PerformanceFigures.Acceleration.mph(acc))
            octane_sum += Baseline.Car.PerformanceFigures.Acceleration.seconds(acc)
        end
    end
    checksum += UInt64(round(octane_sum))

    checksum += UInt64(Baseline.Car.manufacturer(dec)[1])
    checksum += UInt64(Baseline.Car.model(dec)[1])
    checksum += UInt64(Baseline.Car.activationCode(dec)[1])

    SINK[] = checksum
    return nothing
end

encode_car_construct!(DECODE_BUFFER)

const ENCODE_WRAP_CTX = build_encode_wrap_ctx(ENCODE_BUFFER)
const DECODE_WRAP_CTX = build_decode_wrap_ctx(DECODE_BUFFER)

suite = BenchmarkGroup()
suite["encode_construct"] = @benchmarkable encode_car_construct!($ENCODE_BUFFER)
suite["encode_reuse"] = @benchmarkable encode_car_wrap!($ENCODE_WRAP_CTX)
suite["decode_construct"] = @benchmarkable decode_car_construct!($DECODE_BUFFER)
suite["decode_reuse"] = @benchmarkable decode_car_wrap!($DECODE_WRAP_CTX)

results = run(suite; verbose=true)
show(results)

function write_summary(results)
    entries = Dict{String, String}()
    for (name, trial) in results
        estimate = minimum(trial)
        entries[string(name)] = "time_ns=$(estimate.time) memory=$(estimate.memory) allocs=$(estimate.allocs)"
    end
    out_path = get(ENV, "SBE_BENCH_OUT", joinpath(@__DIR__, "results.txt"))
    open(out_path, "w") do io
        for name in sort(collect(keys(entries)))
            println(io, name, " ", entries[name])
        end
    end
end

write_summary(results)
