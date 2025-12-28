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
    enc = Baseline.Car.Encoder(buffer)

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

mutable struct EncodeReuseCtx{E,H,EN,EX,EC,VD,ND}
    buffer::Vector{UInt8}
    enc::E
    header::H
    engine::EN
    extras::EX
    engine_code_dest::EC
    vehicle_dest::VD
    numbers_dest::ND
end

function build_encode_reuse_ctx(buffer::Vector{UInt8})
    header = Baseline.MessageHeader.Encoder(buffer, 0)
    enc = Baseline.Car.Encoder(buffer, 0)

    engine = Baseline.Car.engine(enc)
    extras = Baseline.Car.extras(enc)

    engine_code_dest = Baseline.Engine.manufacturerCode!(engine)
    vehicle_dest = Baseline.Car.vehicleCode!(enc)
    numbers_dest = Baseline.Car.someNumbers!(enc)

    return EncodeReuseCtx(
        buffer,
        enc,
        header,
        engine,
        extras,
        engine_code_dest,
        vehicle_dest,
        numbers_dest,
    )
end

function encode_car_wrap!(ctx::EncodeReuseCtx)
    enc = ctx.enc
    header = ctx.header
    Baseline.MessageHeader.blockLength!(header, SBE.sbe_block_length(enc))
    Baseline.MessageHeader.templateId!(header, SBE.sbe_template_id(enc))
    Baseline.MessageHeader.schemaId!(header, SBE.sbe_schema_id(enc))
    Baseline.MessageHeader.version!(header, SBE.sbe_schema_version(enc))

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

    SBE.sbe_rewind!(enc)

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

function decode_car_construct!(buffer::AbstractVector{UInt8})
    dec = Baseline.Car.Decoder(buffer)

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

mutable struct DecodeReuseCtx{D,EN,EX}
    buffer::Vector{UInt8}
    dec::D
    engine::EN
    extras::EX
end

function build_decode_reuse_ctx(buffer::Vector{UInt8})
    dec = Baseline.Car.Decoder(buffer, 0)
    engine = Baseline.Car.engine(dec)
    extras = Baseline.Car.extras(dec)

    return DecodeReuseCtx(
        buffer,
        dec,
        engine,
        extras,
    )
end

function decode_car_wrap!(ctx::DecodeReuseCtx)
    dec = ctx.dec
    header = Baseline.MessageHeader.Decoder(ctx.buffer, 0)
    if Baseline.MessageHeader.templateId(header) != SBE.sbe_template_id(dec) ||
       Baseline.MessageHeader.schemaId(header) != SBE.sbe_schema_id(dec)
        throw(DomainError("Template id or schema id mismatch"))
    end

    SBE.sbe_rewind!(dec)

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

encode_car_construct!(DECODE_BUFFER)

const ENCODE_REUSE_CTX = build_encode_reuse_ctx(ENCODE_BUFFER)
const DECODE_REUSE_CTX = build_decode_reuse_ctx(DECODE_BUFFER)

suite = BenchmarkGroup()
suite["encode_construct"] = @benchmarkable encode_car_construct!($ENCODE_BUFFER)
suite["encode_reuse"] = @benchmarkable encode_car_wrap!($ENCODE_REUSE_CTX)
suite["decode_construct"] = @benchmarkable decode_car_construct!($DECODE_BUFFER)
suite["decode_reuse"] = @benchmarkable decode_car_wrap!($DECODE_REUSE_CTX)

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
