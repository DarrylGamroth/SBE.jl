using Test
using SBE

# Load baseline (sbe-tool generated) code
include(joinpath(@__DIR__, "baseline", "Baseline.jl"))

# Load our generated code
OurSchema = SBE.load_schema(joinpath(@__DIR__, "example-schema.xml"))

@testset "Interoperability Tests" begin
    @testset "Baseline encodes, our code decodes" begin
        buffer = zeros(UInt8, 1024)
        
        # Encode using baseline (sbe-tool generated) code
        baseline_enc = Baseline.CarEncoder(buffer, 0)
        Baseline.serialNumber!(baseline_enc, UInt64(12345))
        Baseline.modelYear!(baseline_enc, UInt16(2024))
        Baseline.available!(baseline_enc, Baseline.BooleanType.T)
        Baseline.code!(baseline_enc, Baseline.Model.A)
        
        # Set someNumbers array - baseline uses array setter
        some_nums = Baseline.someNumbers!(baseline_enc)
        for i in 1:4
            some_nums[i] = UInt32(100 + i)
        end
        
        # Set vehicleCode
        Baseline.vehicleCode!(baseline_enc, "ABC123")
        
        # Set extras (OptionalExtras set)
        Baseline.extras!(baseline_enc, Baseline.OptionalExtras.sunRoof)
        
        # Set engine composite
        engine = Baseline.engine(baseline_enc)
        Baseline.capacity!(engine, UInt16(2000))
        Baseline.numCylinders!(engine, UInt8(4))
        Baseline.manufacturerCode!(engine, "XYZ")
        Baseline.efficiency!(engine, Int8(85))
        Baseline.boosterEnabled!(engine, Baseline.BooleanType.F)
        
        booster = Baseline.booster(engine)
        Baseline.BoostType!(booster, Baseline.BoostType.TURBO)
        Baseline.horsePower!(booster, UInt8(150))
        
        # Decode using our code
        our_dec = OurSchema.Car.Decoder(buffer, 0)
        
        @test OurSchema.Car.serialNumber(our_dec) == UInt64(12345)
        @test OurSchema.Car.modelYear(our_dec) == UInt16(2024)
        @test OurSchema.Car.available(our_dec) == OurSchema.BooleanType.T
        @test OurSchema.Car.code(our_dec) == OurSchema.Model.A
        
        # Check someNumbers array
        for i in 1:4
            @test OurSchema.Car.someNumbers(our_dec, i) == UInt32(100 + i)
        end
        
        # Check vehicleCode
        @test OurSchema.Car.vehicleCode(our_dec) == "ABC123"
        
        # Check engine composite
        our_engine = OurSchema.Car.engine(our_dec)
        @test OurSchema.Engine.capacity(our_engine) == UInt16(2000)
        @test OurSchema.Engine.numCylinders(our_engine) == UInt8(4)
        @test OurSchema.Engine.manufacturerCode(our_engine) == "XYZ"
        @test OurSchema.Engine.efficiency(our_engine) == Int8(85)
        @test OurSchema.Engine.boosterEnabled(our_engine) == OurSchema.BooleanType.F
        
        our_booster = OurSchema.Engine.booster(our_engine)
        @test OurSchema.Booster.BoostType(our_booster) == OurSchema.BoostType.TURBO
        @test OurSchema.Booster.horsePower(our_booster) == UInt8(150)
        
        println("  ✓ Baseline encoder → Our decoder: SUCCESS")
    end
    
    @testset "Our code encodes, baseline decodes" begin
        buffer = zeros(UInt8, 1024)
        
        # Encode using our code
        our_enc = OurSchema.Car.Encoder(buffer, 0)
        OurSchema.Car.serialNumber!(our_enc, UInt64(67890))
        OurSchema.Car.modelYear!(our_enc, UInt16(2025))
        OurSchema.Car.available!(our_enc, OurSchema.BooleanType.F)
        OurSchema.Car.code!(our_enc, OurSchema.Model.B)
        
        # Set someNumbers array
        for i in 1:4
            OurSchema.Car.someNumbers!(our_enc, i, UInt32(200 + i))
        end
        
        # Set vehicleCode
        OurSchema.Car.vehicleCode!(our_enc, "XYZ789")
        
        # Set extras
        OurSchema.Car.extras!(our_enc, OurSchema.OptionalExtras.sportsPack)
        
        # Set engine composite
        our_engine = OurSchema.Car.engine(our_enc)
        OurSchema.Engine.capacity!(our_engine, UInt16(3000))
        OurSchema.Engine.numCylinders!(our_engine, UInt8(6))
        OurSchema.Engine.manufacturerCode!(our_engine, "ABC")
        OurSchema.Engine.efficiency!(our_engine, Int8(90))
        OurSchema.Engine.boosterEnabled!(our_engine, OurSchema.BooleanType.T)
        
        our_booster = OurSchema.Engine.booster(our_engine)
        OurSchema.Booster.BoostType!(our_booster, OurSchema.BoostType.SUPERCHARGER)
        OurSchema.Booster.horsePower!(our_booster, UInt8(200))
        
        # Decode using baseline (sbe-tool generated) code
        baseline_dec = Baseline.CarDecoder(buffer, 0)
        
        @test Baseline.serialNumber(baseline_dec) == UInt64(67890)
        @test Baseline.modelYear(baseline_dec) == UInt16(2025)
        @test Baseline.available(baseline_dec) == Baseline.BooleanType.F
        @test Baseline.code(baseline_dec) == Baseline.Model.B
        
        # Check someNumbers array
        baseline_nums = Baseline.someNumbers(baseline_dec)
        for i in 1:4
            @test baseline_nums[i] == UInt32(200 + i)
        end
        
        # Check vehicleCode
        @test Baseline.vehicleCode(baseline_dec) == "XYZ789"
        
        # Check engine composite
        baseline_engine = Baseline.engine(baseline_dec)
        @test Baseline.capacity(baseline_engine) == UInt16(3000)
        @test Baseline.numCylinders(baseline_engine) == UInt8(6)
        @test Baseline.manufacturerCode(baseline_engine) == "ABC"
        @test Baseline.efficiency(baseline_engine) == Int8(90)
        @test Baseline.boosterEnabled(baseline_engine) == Baseline.BooleanType.T
        
        baseline_booster = Baseline.booster(baseline_engine)
        @test Baseline.BoostType(baseline_booster) == Baseline.BoostType.SUPERCHARGER
        @test Baseline.horsePower(baseline_booster) == UInt8(200)
        
        println("  ✓ Our encoder → Baseline decoder: SUCCESS")
    end
    
    @testset "Block length comparison" begin
        buffer = zeros(UInt8, 256)
        
        baseline_enc = Baseline.CarEncoder(buffer, 0)
        our_enc = OurSchema.Car.Encoder(buffer, 0)
        
        # Both should have the same block length
        @test Baseline.sbe_acting_block_length(baseline_enc) == SBE.sbe_acting_block_length(our_enc)
        
        println("  ✓ Block lengths match: ", SBE.sbe_acting_block_length(our_enc), " bytes")
    end
end
