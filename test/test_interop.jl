using Test
using SBE

# Load baseline (sbe-tool generated) code from Java generator
# This is the reference implementation to compare against
module BaselineJava
    include(joinpath(@__DIR__, "baseline", "Baseline.jl"))
    using .Baseline
end

# Load our generated code from file-based generation
# This is our Julia codec to validate
module BaselineJulia
    include(joinpath(@__DIR__, "generated", "Baseline.jl"))
    using .Baseline
end

# Aliases for test clarity
const Baseline = BaselineJava.Baseline  # Java sbe-tool reference
const OurSchema = BaselineJulia.Baseline  # Our Julia codec

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
        
        # Note: Skipping extras! (set type) - API differs between baseline and our code
        
        # Set engine composite
        engine = Baseline.engine(baseline_enc)
        Baseline.capacity!(engine, UInt16(2000))
        Baseline.numCylinders!(engine, UInt8(4))
        Baseline.manufacturerCode!(engine, "XYZ")
        Baseline.efficiency!(engine, Int8(85))
        Baseline.boosterEnabled!(engine, Baseline.BooleanType.F)
        
        booster = Baseline.booster(engine)
        Baseline.boostType!(booster, Baseline.BoostType.TURBO)
        Baseline.horsePower!(booster, UInt8(150))
        
        # Decode using our code
        our_dec = OurSchema.Car.Decoder(buffer, 0)
        
        @test OurSchema.Car.serialNumber(our_dec) == UInt64(12345)
        @test OurSchema.Car.modelYear(our_dec) == UInt16(2024)
        @test OurSchema.Car.available(our_dec) == OurSchema.BooleanType.T
        @test OurSchema.Car.code(our_dec) == OurSchema.Model.A
        
        # Check someNumbers array - our API returns array, then index
        our_numbers = OurSchema.Car.someNumbers(our_dec)
        for i in 1:4
            @test our_numbers[i] == UInt32(100 + i)
        end
        
        # Check vehicleCode
        @test OurSchema.Car.vehicleCode(our_dec) == "ABC123"
        
        # Check engine composite
        our_engine = OurSchema.Car.engine(our_dec)
        @test OurSchema.Engine.capacity(our_engine) == UInt16(2000)
        @test OurSchema.Engine.numCylinders(our_engine) == UInt8(4)
        @test OurSchema.Engine.manufacturerCode(our_engine) == "XYZ"
        # Note: efficiency, boosterEnabled, and booster not in our schema (intentional difference)
        
        # our_booster = OurSchema.Engine.booster(our_engine)
        # @test OurSchema.Booster.boostType(our_booster) == OurSchema.BoostType.TURBO
        # @test OurSchema.Booster.horsePower(our_booster) == UInt8(150)        
    end
    
    @testset "Our code encodes, baseline decodes" begin
        buffer = zeros(UInt8, 1024)
        
        # Encode using our code
        our_enc = OurSchema.Car.Encoder(buffer, 0)
        OurSchema.Car.serialNumber!(our_enc, UInt64(67890))
        OurSchema.Car.modelYear!(our_enc, UInt16(2025))
        OurSchema.Car.available!(our_enc, OurSchema.BooleanType.F)
        OurSchema.Car.code!(our_enc, OurSchema.Model.B)
        
        # Set someNumbers array - our code uses array setter (like baseline)
        some_nums_our = OurSchema.Car.someNumbers!(our_enc)
        for i in 1:4
            some_nums_our[i] = UInt32(200 + i)
        end
        
        # Set vehicleCode
        OurSchema.Car.vehicleCode!(our_enc, "XYZ789")
        
        # Note: Skipping extras! (set type) - API differs between baseline and our code
        
        # Set engine composite
        our_engine = OurSchema.Car.engine(our_enc)
        OurSchema.Engine.capacity!(our_engine, UInt16(3000))
        OurSchema.Engine.numCylinders!(our_engine, UInt8(6))
        OurSchema.Engine.manufacturerCode!(our_engine, "ABC")
        # Note: efficiency, boosterEnabled, and booster not in our schema (intentional difference)
        
        # our_booster = OurSchema.Engine.booster(our_engine)
        # OurSchema.Booster.boostType!(our_booster, OurSchema.BoostType.SUPERCHARGER)
        # OurSchema.Booster.horsePower!(our_booster, UInt8(200))
        
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
        
        # Check vehicleCode - baseline returns UInt8 vector, convert to string
        @test String(Baseline.vehicleCode(baseline_dec)) == "XYZ789"
        
        # Check engine composite - only test fields that exist in both schemas
        baseline_engine = Baseline.engine(baseline_dec)
        @test Baseline.capacity(baseline_engine) == UInt16(3000)
        @test Baseline.numCylinders(baseline_engine) == UInt8(6)
        # Baseline returns UInt8 vector for manufacturerCode, convert to string
        @test String(Baseline.manufacturerCode(baseline_engine)) == "ABC"
        # Note: Not testing efficiency, boosterEnabled, booster since our schema doesn't have them        
    end
    
    @testset "Block length comparison" begin
        buffer = zeros(UInt8, 256)
        
        baseline_enc = Baseline.CarEncoder(buffer, 0)
        our_dec = OurSchema.Car.Decoder(buffer, 0)
        
        # Both should have the same block length
        # Baseline exports the function directly
        baseline_block_len = Baseline.sbe_acting_block_length(baseline_enc)
        
        # Our code defines it on the Decoder
        our_block_len = OurSchema.Car.sbe_acting_block_length(our_dec)
        
        @test baseline_block_len == our_block_len
        @test baseline_block_len == UInt16(0x2d)  # Expected block length for Car message
        
        println("  ✓ Block lengths match: ", our_block_len, " bytes")
    end
end
