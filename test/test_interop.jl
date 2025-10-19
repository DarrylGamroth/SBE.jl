using Test
using SBE
using StringViews: StringView

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
        
        # Set extras (bitset type)
        extras_enc = Baseline.extras(baseline_enc)
        Baseline.sunRoof!(extras_enc, true)
        Baseline.sportsPack!(extras_enc, false)
        Baseline.cruiseControl!(extras_enc, true)
        
        # Set engine composite
        engine = Baseline.engine(baseline_enc)
        Baseline.capacity!(engine, UInt16(2000))
        Baseline.numCylinders!(engine, UInt8(4))
        Baseline.manufacturerCode!(engine, "XYZ")
        Baseline.efficiency!(engine, Int8(85))
        Baseline.boosterEnabled!(engine, Baseline.BooleanType.T)
        
        booster = Baseline.booster(engine)
        Baseline.boostType!(booster, Baseline.BoostType.TURBO)
        Baseline.horsePower!(booster, UInt8(150))
        
        # Decode using our code
        our_dec = OurSchema.Car.Decoder(buffer, 0)
        
        # Test all primitive fields
        @test OurSchema.Car.serialNumber(our_dec) == UInt64(12345)
        @test OurSchema.Car.modelYear(our_dec) == UInt16(2024)
        @test OurSchema.Car.available(our_dec) == OurSchema.BooleanType.T
        @test OurSchema.Car.code(our_dec) == OurSchema.Model.A
        
        # Test array field
        our_numbers = OurSchema.Car.someNumbers(our_dec)
        for i in 1:4
            @test our_numbers[i] == UInt32(100 + i)
        end
        
        # Test string field
        @test OurSchema.Car.vehicleCode(our_dec) == "ABC123"
        
        # Test bitset field
        extras_dec = OurSchema.Car.extras(our_dec)
        @test OurSchema.OptionalExtras.sunRoof(extras_dec) == true
        @test OurSchema.OptionalExtras.sportsPack(extras_dec) == false
        @test OurSchema.OptionalExtras.cruiseControl(extras_dec) == true
        
        # Test constant field (should always return Model.C)
        @test OurSchema.Car.discountedModel(our_dec) == OurSchema.Model.C
        
        # Test composite field (Engine)
        our_engine = OurSchema.Car.engine(our_dec)
        @test OurSchema.Engine.capacity(our_engine) == UInt16(2000)
        @test OurSchema.Engine.numCylinders(our_engine) == UInt8(4)
        @test OurSchema.Engine.manufacturerCode(our_engine) == "XYZ"
        @test OurSchema.Engine.maxRpm(our_engine) == UInt16(9000)  # Constant field
        @test String(OurSchema.Engine.fuel(our_engine)) == "Petrol"  # Constant string
        @test OurSchema.Engine.efficiency(our_engine) == Int8(85)
        @test OurSchema.Engine.boosterEnabled(our_engine) == OurSchema.BooleanType.T
        
        # Test nested composite field (Booster inside Engine)
        our_booster = OurSchema.Engine.booster(our_engine)
        @test OurSchema.Booster.boostType(our_booster) == OurSchema.Booster.BoostType.TURBO
        @test OurSchema.Booster.horsePower(our_booster) == UInt8(150)
    end
    
        @testset "Our code encodes, Baseline decodes" begin
        buffer = zeros(UInt8, 1024)
        
        # Encode using our code
        our_enc = OurSchema.Car.Encoder(buffer, 0)
        OurSchema.Car.serialNumber!(our_enc, UInt64(67890))
        OurSchema.Car.modelYear!(our_enc, UInt16(2025))
        OurSchema.Car.available!(our_enc, OurSchema.BooleanType.F)
        OurSchema.Car.code!(our_enc, OurSchema.Model.B)
        
        # Set someNumbers array
        some_nums = OurSchema.Car.someNumbers!(our_enc)
        for i in 1:4
            some_nums[i] = UInt32(200 + i)
        end
        
        # Set vehicleCode
        OurSchema.Car.vehicleCode!(our_enc, "DEF456")
        
        # Set extras (bitset type)
        extras_enc = OurSchema.Car.extras(our_enc)
        OurSchema.OptionalExtras.sunRoof!(extras_enc, false)
        OurSchema.OptionalExtras.sportsPack!(extras_enc, true)
        OurSchema.OptionalExtras.cruiseControl!(extras_enc, false)
        
        # Set engine composite
        engine = OurSchema.Car.engine(our_enc)
        OurSchema.Engine.capacity!(engine, UInt16(3000))
        OurSchema.Engine.numCylinders!(engine, UInt8(6))
        OurSchema.Engine.manufacturerCode!(engine, "ABC")
        OurSchema.Engine.efficiency!(engine, Int8(90))
        OurSchema.Engine.boosterEnabled!(engine, OurSchema.BooleanType.T)
        
        booster = OurSchema.Engine.booster(engine)
        OurSchema.Booster.boostType!(booster, OurSchema.Booster.BoostType.SUPERCHARGER)
        OurSchema.Booster.horsePower!(booster, UInt8(200))
        
        # Decode using baseline code
        baseline_dec = Baseline.CarDecoder(buffer, 0)
        
        # Test all primitive fields
        @test Baseline.serialNumber(baseline_dec) == UInt64(67890)
        @test Baseline.modelYear(baseline_dec) == UInt16(2025)
        @test Baseline.available(baseline_dec) == Baseline.BooleanType.F
        @test Baseline.code(baseline_dec) == Baseline.Model.B
        
        # Test array field
        baseline_numbers = Baseline.someNumbers(baseline_dec)
        for i in 1:4
            @test baseline_numbers[i] == UInt32(200 + i)
        end
        
        # Test string field
        @test Baseline.vehicleCode(baseline_dec, String) == "DEF456"
        
        # Test bitset field
        extras_dec = Baseline.extras(baseline_dec)
        @test Baseline.sunRoof(extras_dec) == false
        @test Baseline.sportsPack(extras_dec) == true
        @test Baseline.cruiseControl(extras_dec) == false
        
        # Test constant field (should always return Model.C)
        @test Baseline.discountedModel(baseline_dec) == Baseline.Model.C
        
        # Test composite field (Engine)
        baseline_engine = Baseline.engine(baseline_dec)
        @test Baseline.capacity(baseline_engine) == UInt16(3000)
        @test Baseline.numCylinders(baseline_engine) == UInt8(6)
        @test Baseline.manufacturerCode(baseline_engine, String) == "ABC"
        @test Baseline.maxRpm(baseline_engine) == UInt16(9000)  # Constant field
        @test String(Baseline.fuel(baseline_engine)) == "Petrol"  # Constant string
        @test Baseline.efficiency(baseline_engine) == Int8(90)
        @test Baseline.boosterEnabled(baseline_engine) == Baseline.BooleanType.T
        
        # Test nested composite field (Booster inside Engine)
        baseline_booster = Baseline.booster(baseline_engine)
        @test Baseline.boostType(baseline_booster) == Baseline.BoostType.SUPERCHARGER
        @test Baseline.horsePower(baseline_booster) == UInt8(200)
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
    end
    
    @testset "Groups: Baseline encodes, our code decodes" begin
        buffer = zeros(UInt8, 2048)
        
        # Encode using baseline
        baseline_enc = Baseline.CarEncoder(buffer, 0)
        Baseline.serialNumber!(baseline_enc, UInt64(99999))
        Baseline.modelYear!(baseline_enc, UInt16(2023))
        Baseline.available!(baseline_enc, Baseline.BooleanType.T)
        Baseline.code!(baseline_enc, Baseline.Model.C)
        
        # Set fuelFigures group (2 entries)
        fuel_group = Baseline.fuelFigures!(baseline_enc, 2)
        
        # First fuel figure
        Baseline.next!(fuel_group)
        Baseline.speed!(fuel_group, UInt16(30))
        Baseline.mpg!(fuel_group, Float32(35.5))
        Baseline.usageDescription!(fuel_group, "Urban")
        
        # Second fuel figure
        Baseline.next!(fuel_group)
        Baseline.speed!(fuel_group, UInt16(60))
        Baseline.mpg!(fuel_group, Float32(48.2))
        Baseline.usageDescription!(fuel_group, "Highway")
        
        # Set performanceFigures group (1 entry with nested acceleration group)
        perf_group = Baseline.performanceFigures!(baseline_enc, 1)
        Baseline.next!(perf_group)
        Baseline.octaneRating!(perf_group, UInt8(95))
        
        # Nested acceleration group (3 entries)
        accel_group = Baseline.acceleration!(perf_group, 3)
        Baseline.next!(accel_group)
        Baseline.mph!(accel_group, UInt16(30))
        Baseline.seconds!(accel_group, Float32(4.0))
        
        Baseline.next!(accel_group)
        Baseline.mph!(accel_group, UInt16(60))
        Baseline.seconds!(accel_group, Float32(7.5))
        
        Baseline.next!(accel_group)
        Baseline.mph!(accel_group, UInt16(100))
        Baseline.seconds!(accel_group, Float32(12.2))
        
        # Decode using our code
        our_dec = OurSchema.Car.Decoder(buffer, 0)
        
        @test OurSchema.Car.serialNumber(our_dec) == UInt64(99999)
        @test OurSchema.Car.modelYear(our_dec) == UInt16(2023)
        
        # Decode fuelFigures group
        our_fuel_group = OurSchema.Car.fuelFigures(our_dec)
        @test length(our_fuel_group) == 2
        
        # First entry
        OurSchema.Car.FuelFigures.next!(our_fuel_group)
        @test OurSchema.Car.FuelFigures.speed(our_fuel_group) == UInt16(30)
        @test OurSchema.Car.FuelFigures.mpg(our_fuel_group) == Float32(35.5)
        @test String(OurSchema.Car.FuelFigures.usageDescription(our_fuel_group)) == "Urban"
        
        # Second entry
        OurSchema.Car.FuelFigures.next!(our_fuel_group)
        @test OurSchema.Car.FuelFigures.speed(our_fuel_group) == UInt16(60)
        @test OurSchema.Car.FuelFigures.mpg(our_fuel_group) == Float32(48.2)
        @test String(OurSchema.Car.FuelFigures.usageDescription(our_fuel_group)) == "Highway"
        
        # Decode performanceFigures group
        our_perf_group = OurSchema.Car.performanceFigures(our_dec)
        @test length(our_perf_group) == 1
        
        OurSchema.Car.PerformanceFigures.next!(our_perf_group)
        @test OurSchema.Car.PerformanceFigures.octaneRating(our_perf_group) == UInt8(95)
        
        # Decode nested acceleration group
        our_accel_group = OurSchema.Car.PerformanceFigures.acceleration(our_perf_group)
        @test length(our_accel_group) == 3
        
        # First acceleration entry
        OurSchema.Car.PerformanceFigures.Acceleration.next!(our_accel_group)
        @test OurSchema.Car.PerformanceFigures.Acceleration.mph(our_accel_group) == UInt16(30)
        @test OurSchema.Car.PerformanceFigures.Acceleration.seconds(our_accel_group) == Float32(4.0)
        
        # Second acceleration entry
        OurSchema.Car.PerformanceFigures.Acceleration.next!(our_accel_group)
        @test OurSchema.Car.PerformanceFigures.Acceleration.mph(our_accel_group) == UInt16(60)
        @test OurSchema.Car.PerformanceFigures.Acceleration.seconds(our_accel_group) == Float32(7.5)
        
        # Third acceleration entry
        OurSchema.Car.PerformanceFigures.Acceleration.next!(our_accel_group)
        @test OurSchema.Car.PerformanceFigures.Acceleration.mph(our_accel_group) == UInt16(100)
        @test OurSchema.Car.PerformanceFigures.Acceleration.seconds(our_accel_group) == Float32(12.2)
    end
    
    @testset "Groups: Our code encodes, Baseline decodes" begin
        buffer = zeros(UInt8, 2048)
        
        # Encode using our code
        our_enc = OurSchema.Car.Encoder(buffer, 0)
        OurSchema.Car.serialNumber!(our_enc, UInt64(88888))
        OurSchema.Car.modelYear!(our_enc, UInt16(2024))
        OurSchema.Car.available!(our_enc, OurSchema.BooleanType.F)
        OurSchema.Car.code!(our_enc, OurSchema.Model.A)
        
        # Set fuelFigures group (3 entries)
        fuel_group = OurSchema.Car.fuelFigures!(our_enc, 3)
        
        # First fuel figure
        OurSchema.Car.FuelFigures.next!(fuel_group)
        OurSchema.Car.FuelFigures.speed!(fuel_group, UInt16(25))
        OurSchema.Car.FuelFigures.mpg!(fuel_group, Float32(30.0))
        OurSchema.Car.FuelFigures.usageDescription!(fuel_group, "City")
        
        # Second fuel figure
        OurSchema.Car.FuelFigures.next!(fuel_group)
        OurSchema.Car.FuelFigures.speed!(fuel_group, UInt16(55))
        OurSchema.Car.FuelFigures.mpg!(fuel_group, Float32(45.0))
        OurSchema.Car.FuelFigures.usageDescription!(fuel_group, "Combined")
        
        # Third fuel figure
        OurSchema.Car.FuelFigures.next!(fuel_group)
        OurSchema.Car.FuelFigures.speed!(fuel_group, UInt16(70))
        OurSchema.Car.FuelFigures.mpg!(fuel_group, Float32(50.5))
        OurSchema.Car.FuelFigures.usageDescription!(fuel_group, "Motorway")
        
        # Set performanceFigures group (2 entries)
        perf_group = OurSchema.Car.performanceFigures!(our_enc, 2)
        
        # First performance figure with nested acceleration
        OurSchema.Car.PerformanceFigures.next!(perf_group)
        OurSchema.Car.PerformanceFigures.octaneRating!(perf_group, UInt8(91))
        
        accel_group1 = OurSchema.Car.PerformanceFigures.acceleration!(perf_group, 2)
        OurSchema.Car.PerformanceFigures.Acceleration.next!(accel_group1)
        OurSchema.Car.PerformanceFigures.Acceleration.mph!(accel_group1, UInt16(30))
        OurSchema.Car.PerformanceFigures.Acceleration.seconds!(accel_group1, Float32(5.0))
        
        OurSchema.Car.PerformanceFigures.Acceleration.next!(accel_group1)
        OurSchema.Car.PerformanceFigures.Acceleration.mph!(accel_group1, UInt16(60))
        OurSchema.Car.PerformanceFigures.Acceleration.seconds!(accel_group1, Float32(9.0))
        
        # Second performance figure with nested acceleration
        OurSchema.Car.PerformanceFigures.next!(perf_group)
        OurSchema.Car.PerformanceFigures.octaneRating!(perf_group, UInt8(98))
        
        accel_group2 = OurSchema.Car.PerformanceFigures.acceleration!(perf_group, 1)
        OurSchema.Car.PerformanceFigures.Acceleration.next!(accel_group2)
        OurSchema.Car.PerformanceFigures.Acceleration.mph!(accel_group2, UInt16(30))
        OurSchema.Car.PerformanceFigures.Acceleration.seconds!(accel_group2, Float32(3.5))
        
        # Decode using baseline
        baseline_dec = Baseline.CarDecoder(buffer, 0)
        
        @test Baseline.serialNumber(baseline_dec) == UInt64(88888)
        @test Baseline.modelYear(baseline_dec) == UInt16(2024)
        
        # Decode fuelFigures group
        baseline_fuel_group = Baseline.fuelFigures(baseline_dec)
        @test length(baseline_fuel_group) == 3
        
        # First entry
        Baseline.next!(baseline_fuel_group)
        @test Baseline.speed(baseline_fuel_group) == UInt16(25)
        @test Baseline.mpg(baseline_fuel_group) == Float32(30.0)
        @test String(Baseline.usageDescription(baseline_fuel_group, StringView)) == "City"
        
        # Second entry
        Baseline.next!(baseline_fuel_group)
        @test Baseline.speed(baseline_fuel_group) == UInt16(55)
        @test Baseline.mpg(baseline_fuel_group) == Float32(45.0)
        @test String(Baseline.usageDescription(baseline_fuel_group, StringView)) == "Combined"
        
        # Third entry
        Baseline.next!(baseline_fuel_group)
        @test Baseline.speed(baseline_fuel_group) == UInt16(70)
        @test Baseline.mpg(baseline_fuel_group) == Float32(50.5)
        @test String(Baseline.usageDescription(baseline_fuel_group, StringView)) == "Motorway"
        
        # Decode performanceFigures group
        baseline_perf_group = Baseline.performanceFigures(baseline_dec)
        @test length(baseline_perf_group) == 2
        
        # First performance figure
        Baseline.next!(baseline_perf_group)
        @test Baseline.octaneRating(baseline_perf_group) == UInt8(91)
        baseline_accel1 = Baseline.acceleration(baseline_perf_group)
        @test length(baseline_accel1) == 2
        
        Baseline.next!(baseline_accel1)
        @test Baseline.mph(baseline_accel1) == UInt16(30)
        @test Baseline.seconds(baseline_accel1) == Float32(5.0)
        
        Baseline.next!(baseline_accel1)
        @test Baseline.mph(baseline_accel1) == UInt16(60)
        @test Baseline.seconds(baseline_accel1) == Float32(9.0)
        
        # Second performance figure
        Baseline.next!(baseline_perf_group)
        @test Baseline.octaneRating(baseline_perf_group) == UInt8(98)
        baseline_accel2 = Baseline.acceleration(baseline_perf_group)
        @test length(baseline_accel2) == 1
        
        Baseline.next!(baseline_accel2)
        @test Baseline.mph(baseline_accel2) == UInt16(30)
        @test Baseline.seconds(baseline_accel2) == Float32(3.5)
    end
end
