using Test
using SBE

@testset "Repeating Groups" begin
    # Use pre-generated Baseline module (loaded by runtests.jl)
    # Baseline should already be defined in Main scope
    
    @testset "Group Types and Module Structure" begin
        # Verify group modules are exported
        @test isdefined(Baseline.Car, :FuelFigures)
        @test isdefined(Baseline.Car, :PerformanceFigures)
        
        # Verify Decoder and Encoder types exist in group modules
        @test isdefined(Baseline.Car.FuelFigures, :Decoder)
        @test isdefined(Baseline.Car.FuelFigures, :Encoder)
        @test isdefined(Baseline.Car.PerformanceFigures, :Decoder)
        @test isdefined(Baseline.Car.PerformanceFigures, :Encoder)
        
        # Verify AbstractSbeGroup inheritance
        buffer = zeros(UInt8, 256)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        fuel = Baseline.Car.fuelFigures!(car_enc, 1)
        @test fuel isa SBE.AbstractSbeGroup
        
        perf = Baseline.Car.performanceFigures!(car_enc, 1)
        @test perf isa SBE.AbstractSbeGroup
        
        # Verify accessor functions are exported
        @test hasmethod(Baseline.Car.fuelFigures!, (Baseline.Car.Encoder, Any))
        @test hasmethod(Baseline.Car.performanceFigures!, (Baseline.Car.Encoder, Any))
    end

    @testset "Type-Level SBE Metadata" begin
        buffer = zeros(UInt8, 256)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)

        # Message metadata on types
        @test SBE.sbe_block_length(car_enc) == Baseline.Car.sbe_block_length(Baseline.Car.Decoder)
        @test SBE.sbe_template_id(car_enc) == Baseline.Car.sbe_template_id(Baseline.Car.Decoder)
        @test SBE.sbe_schema_id(car_enc) == Baseline.Car.sbe_schema_id(Baseline.Car.Decoder)
        @test SBE.sbe_schema_version(car_enc) == Baseline.Car.sbe_schema_version(Baseline.Car.Decoder)

        # Group metadata on types
        @test Baseline.Car.FuelFigures.sbe_header_size(Baseline.Car.FuelFigures.Decoder) == 4
        @test Baseline.Car.FuelFigures.sbe_block_length(Baseline.Car.FuelFigures.Decoder) ==
              Baseline.Car.FuelFigures.sbe_block_length(Baseline.Car.FuelFigures.Encoder)
        @test Baseline.Car.FuelFigures.sbe_acting_version(Baseline.Car.FuelFigures.Decoder) ==
              Baseline.Car.FuelFigures.sbe_acting_version(Baseline.Car.FuelFigures.AbstractFuelFigures)
    end
    
    @testset "Empty Group Encoding" begin
        buffer = zeros(UInt8, 256)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        
        # Create empty fuel figures group
        fuel = Baseline.Car.fuelFigures!(car_enc, 0)
        @test length(fuel) == 0
        @test Base.isdone(fuel)  # Empty group is immediately done
        
        # Verify dimension header for empty group
        header_size = 8
        message_block = SBE.sbe_block_length(car_enc)
        dim_offset = header_size + message_block
        
        block_len = reinterpret(UInt16, view(buffer, dim_offset+1:dim_offset+2))[1]
        num_in_group = reinterpret(UInt16, view(buffer, dim_offset+3:dim_offset+4))[1]
        @test block_len == 6  # speed (2) + mpg (4)
        @test num_in_group == 0
    end
    
    @testset "Basic Group Encoding" begin
        buffer = zeros(UInt8, 256)
        
        # Create encoder (writes header automatically)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        
        # Create and encode group with 2 elements
        fuel_enc = Baseline.Car.fuelFigures!(car_enc, 2)
        @test length(fuel_enc) == 2
        
        # Write first element
        Baseline.Car.FuelFigures.next!(fuel_enc)
        Baseline.Car.FuelFigures.speed!(fuel_enc, 100)
        Baseline.Car.FuelFigures.mpg!(fuel_enc, 35.5)
        
        # Write second element
        Baseline.Car.FuelFigures.next!(fuel_enc)
        Baseline.Car.FuelFigures.speed!(fuel_enc, 120)
        Baseline.Car.FuelFigures.mpg!(fuel_enc, 28.3)
        
        # Now decode and verify (decoder reads header)
        car_dec = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(car_dec, buffer, 0)
        fuel_dec = Baseline.Car.fuelFigures(car_dec)
        
        @test length(fuel_dec) == 2
        
        # Check first element
        elem1 = iterate(fuel_dec)
        @test elem1 !== nothing
        (item1, state1) = elem1
        @test Baseline.Car.FuelFigures.speed(item1) == 100
        @test Baseline.Car.FuelFigures.mpg(item1) ≈ 35.5f0
        
        # Check second element
        elem2 = iterate(fuel_dec, state1)
        @test elem2 !== nothing
        (item2, state2) = elem2
        @test Baseline.Car.FuelFigures.speed(item2) == 120
        @test Baseline.Car.FuelFigures.mpg(item2) ≈ 28.3f0
    end
    
    @testset "Iterator Protocol" begin
        buffer = zeros(UInt8, 256)
        
        # Create encoder (writes header)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        fuel_enc = Baseline.Car.fuelFigures!(car_enc, 3)
        
        # Encode using next!
        test_speeds = [100, 120, 80]
        test_mpgs = [35.0, 32.5, 40.0]
        for (speed, mpg) in zip(test_speeds, test_mpgs)
            Baseline.Car.FuelFigures.next!(fuel_enc)
            Baseline.Car.FuelFigures.speed!(fuel_enc, speed)
            Baseline.Car.FuelFigures.mpg!(fuel_enc, mpg)
        end
        
        # Decode and verify using iteration (decoder reads header)
        car_dec = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(car_dec, buffer, 0)
        fuel_dec = Baseline.Car.fuelFigures(car_dec)
        
        speeds_decoded = UInt16[]
        mpgs_decoded = Float32[]
        for item in fuel_dec
            push!(speeds_decoded, Baseline.Car.FuelFigures.speed(item))
            push!(mpgs_decoded, Baseline.Car.FuelFigures.mpg(item))
        end
        
        @test speeds_decoded == test_speeds
        @test all(mpgs_decoded .≈ Float32.(test_mpgs))
    end

    @testset "Group Decoder Reuse" begin
        function encode_fuel!(buffer, speeds, mpgs)
            car_enc = Baseline.Car.Encoder(typeof(buffer))
            Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
            fuel_enc = Baseline.Car.fuelFigures!(car_enc, length(speeds))
            for (speed, mpg) in zip(speeds, mpgs)
                Baseline.Car.FuelFigures.next!(fuel_enc)
                Baseline.Car.FuelFigures.speed!(fuel_enc, speed)
                Baseline.Car.FuelFigures.mpg!(fuel_enc, mpg)
            end
            return buffer
        end

        buffer1 = zeros(UInt8, 256)
        encode_fuel!(buffer1, [100, 120], [35.5, 28.3])
        dec1 = Baseline.Car.Decoder(typeof(buffer1))
        Baseline.Car.wrap!(dec1, buffer1, 0)
        fuel_dec = Baseline.Car.fuelFigures(dec1)
        speeds1 = [Baseline.Car.FuelFigures.speed(item) for item in fuel_dec]
        @test speeds1 == UInt16[100, 120]

        buffer2 = zeros(UInt8, 256)
        encode_fuel!(buffer2, [80, 90], [40.0, 41.0])
        dec2 = Baseline.Car.Decoder(typeof(buffer2))
        Baseline.Car.wrap!(dec2, buffer2, 0)
        reused = Baseline.Car.fuelFigures!(dec2, fuel_dec)
        @test reused === fuel_dec
        speeds2 = [Baseline.Car.FuelFigures.speed(item) for item in reused]
        @test speeds2 == UInt16[80, 90]
    end
    
    @testset "Base.eltype" begin
        buffer = zeros(UInt8, 256)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        fuel_enc = Baseline.Car.fuelFigures!(car_enc, 1)
        
        # Encoder eltype returns Encoder type
        @test Base.eltype(fuel_enc) == Baseline.Car.FuelFigures.Encoder
    end
    
    @testset "Base.isdone" begin
        buffer = zeros(UInt8, 256)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        fuel = Baseline.Car.fuelFigures!(car_enc, 2)
        
        # Not done initially
        @test !Base.isdone(fuel)
        
        # Not done after first element
        Baseline.Car.FuelFigures.next!(fuel)
        @test !Base.isdone(fuel)
        
        # Done after second element
        Baseline.Car.FuelFigures.next!(fuel)
        @test Base.isdone(fuel)
    end
    
    @testset "Position Management" begin
        buffer = zeros(UInt8, 256)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        
        # Record position before group
        pos_before = SBE.sbe_position(car_enc)
        
        # Create group with 2 elements
        fuel = Baseline.Car.fuelFigures!(car_enc, 2)
        Baseline.Car.FuelFigures.next!(fuel)
        Baseline.Car.FuelFigures.speed!(fuel, 100)
        Baseline.Car.FuelFigures.mpg!(fuel, 35.5)
        Baseline.Car.FuelFigures.next!(fuel)
        Baseline.Car.FuelFigures.speed!(fuel, 120)
        Baseline.Car.FuelFigures.mpg!(fuel, 28.3)
        
        # Position should have advanced by: dimension header (4) + 2 elements (6 bytes each)
        expected_position = pos_before + 4 + 2 * 6
        @test SBE.sbe_position(car_enc) == expected_position
        
        # Group shares position pointer with message
        @test SBE.sbe_position(fuel) == SBE.sbe_position(car_enc)
    end
    
    @testset "Count Validation" begin
        buffer = zeros(UInt8, 256)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        
        # Test maximum count (65534)
        @test_throws ErrorException Baseline.Car.fuelFigures!(car_enc, 65535)
    end
    
    @testset "reset_count_to_index!" begin
        buffer = zeros(UInt8, 256)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        
        # Create group with count=5 but only write 3 elements
        fuel = Baseline.Car.fuelFigures!(car_enc, 5)
        
        for i in 1:3
            Baseline.Car.FuelFigures.next!(fuel)
            Baseline.Car.FuelFigures.speed!(fuel, i * 10)
            Baseline.Car.FuelFigures.mpg!(fuel, 30.0)
        end
        
        # Reset count to actual number written
        final_count = Baseline.Car.FuelFigures.reset_count_to_index!(fuel)
        @test final_count == 3
        
        # Verify dimension header was updated in buffer
        header_size = 8
        message_block_length = SBE.sbe_block_length(car_enc)
        dim_offset = header_size + message_block_length
        num_in_group = reinterpret(UInt16, view(buffer, dim_offset+3:dim_offset+4))[1]
        @test num_in_group == 3
    end
    
    @testset "Multiple Groups in Message" begin
        buffer = zeros(UInt8, 512)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        
        # Write first group (fuelFigures)
        fuel = Baseline.Car.fuelFigures!(car_enc, 2)
        Baseline.Car.FuelFigures.next!(fuel)
        Baseline.Car.FuelFigures.speed!(fuel, 100)
        Baseline.Car.FuelFigures.mpg!(fuel, 35.5)
        Baseline.Car.FuelFigures.next!(fuel)
        Baseline.Car.FuelFigures.speed!(fuel, 120)
        Baseline.Car.FuelFigures.mpg!(fuel, 28.3)
        
        pos_after_fuel = SBE.sbe_position(car_enc)
        
        # Write second group (performanceFigures)
        perf = Baseline.Car.performanceFigures!(car_enc, 1)
        Baseline.Car.PerformanceFigures.next!(perf)
        Baseline.Car.PerformanceFigures.octaneRating!(perf, 0x5f)  # RON 95
        
        # Verify position advanced correctly
        perf_size = 4 + 1 * 1  # dimension header + 1 element of 1 byte
        @test SBE.sbe_position(car_enc) == pos_after_fuel + perf_size
    end
    
    @testset "Nested Groups - Structure" begin
        # Verify nested group module exists
        @test isdefined(Baseline.Car.PerformanceFigures, :Acceleration)
        @test isdefined(Baseline.Car.PerformanceFigures.Acceleration, :Decoder)
        @test isdefined(Baseline.Car.PerformanceFigures.Acceleration, :Encoder)
        
        # Verify nested group inherits from AbstractSbeGroup
        buffer = zeros(UInt8, 512)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        perf = Baseline.Car.performanceFigures!(car_enc, 1)
        Baseline.Car.PerformanceFigures.next!(perf)
        Baseline.Car.PerformanceFigures.octaneRating!(perf, 95)
        
        accel = Baseline.Car.PerformanceFigures.acceleration!(perf, 1)
        @test accel isa SBE.AbstractSbeGroup
    end
    
    @testset "Nested Groups - Encoding" begin
        buffer = zeros(UInt8, 512)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        
        # Create performance figures with nested acceleration
        perf = Baseline.Car.performanceFigures!(car_enc, 2)
        
        # First performance figure with 2 accelerations
        Baseline.Car.PerformanceFigures.next!(perf)
        Baseline.Car.PerformanceFigures.octaneRating!(perf, 95)
        
        accel1 = Baseline.Car.PerformanceFigures.acceleration!(perf, 2)
        Baseline.Car.PerformanceFigures.Acceleration.next!(accel1)
        Baseline.Car.PerformanceFigures.Acceleration.mph!(accel1, 30)
        Baseline.Car.PerformanceFigures.Acceleration.seconds!(accel1, 4.0)
        
        Baseline.Car.PerformanceFigures.Acceleration.next!(accel1)
        Baseline.Car.PerformanceFigures.Acceleration.mph!(accel1, 60)
        Baseline.Car.PerformanceFigures.Acceleration.seconds!(accel1, 7.5)
        
        # Second performance figure with 1 acceleration
        Baseline.Car.PerformanceFigures.next!(perf)
        Baseline.Car.PerformanceFigures.octaneRating!(perf, 99)
        
        accel2 = Baseline.Car.PerformanceFigures.acceleration!(perf, 1)
        Baseline.Car.PerformanceFigures.Acceleration.next!(accel2)
        Baseline.Car.PerformanceFigures.Acceleration.mph!(accel2, 30)
        Baseline.Car.PerformanceFigures.Acceleration.seconds!(accel2, 3.5)
        
        # Verify data structure in buffer
        # Should have: performanceFigures dimension header + 2 elements,
        # each with octaneRating + acceleration dimension header + acceleration data
        header_size = 8
        message_block = SBE.sbe_block_length(car_enc)
        perf_dim_offset = header_size + message_block
        
        # Check performanceFigures dimension header
        perf_count = reinterpret(UInt16, view(buffer, perf_dim_offset+3:perf_dim_offset+4))[1]
        @test perf_count == 2
        
        # Position should account for all nested data
        # perf dim (4) + perf1 octane (1) + accel1 dim (4) + accel1 data (2*6=12) +
        # perf2 octane (1) + accel2 dim (4) + accel2 data (1*6=6)
        expected_size = 4 + (1 + 4 + 12) + (1 + 4 + 6)
        @test SBE.sbe_position(car_enc) == header_size + message_block + expected_size
    end
    
    @testset "Nested Groups - Iterator" begin
        buffer = zeros(UInt8, 512)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        
        perf = Baseline.Car.performanceFigures!(car_enc, 1)
        Baseline.Car.PerformanceFigures.next!(perf)
        Baseline.Car.PerformanceFigures.octaneRating!(perf, 95)
        
        # Create nested group and verify iteration
        accel = Baseline.Car.PerformanceFigures.acceleration!(perf, 3)
        @test length(accel) == 3
        @test !Base.isdone(accel)
        
        # Write all elements
        for i in 1:3
            Baseline.Car.PerformanceFigures.Acceleration.next!(accel)
            Baseline.Car.PerformanceFigures.Acceleration.mph!(accel, i * 30)
            Baseline.Car.PerformanceFigures.Acceleration.seconds!(accel, Float32(i * 2.5))
        end
        
        @test Base.isdone(accel)
    end
    
    @testset "Variable-Length Data in Groups" begin
        buffer = zeros(UInt8, 512)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        
        # Create fuel figures with var data
        fuel = Baseline.Car.fuelFigures!(car_enc, 2)
        
        # First element with var data
        Baseline.Car.FuelFigures.next!(fuel)
        Baseline.Car.FuelFigures.speed!(fuel, 55)
        Baseline.Car.FuelFigures.mpg!(fuel, 42.0)
        Baseline.Car.FuelFigures.usageDescription!(fuel, "City driving")
        
        # Second element with different var data
        Baseline.Car.FuelFigures.next!(fuel)
        Baseline.Car.FuelFigures.speed!(fuel, 75)
        Baseline.Car.FuelFigures.mpg!(fuel, 38.5)
        Baseline.Car.FuelFigures.usageDescription!(fuel, "Highway cruising")
        
        # Verify position accounts for fixed fields + var data
        # 2 elements * 6 bytes fixed + var data (4 + 12) + (4 + 16) = 12 + 16 + 20 = 48
        header_size = 8
        message_block = SBE.sbe_block_length(car_enc)
        
        # Each element: speed (2) + mpg (4) + vardata_header (4) + vardata_content
        # Element 1: 6 + 4 + 12 = 22
        # Element 2: 6 + 4 + 16 = 26
        # Total: dimension (4) + 22 + 26 = 52
        expected_pos = header_size + message_block + 52
        @test SBE.sbe_position(car_enc) == expected_pos
    end
    
    @testset "Variable-Length Data - Empty String" begin
        buffer = zeros(UInt8, 256)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        
        fuel = Baseline.Car.fuelFigures!(car_enc, 1)
        Baseline.Car.FuelFigures.next!(fuel)
        Baseline.Car.FuelFigures.speed!(fuel, 60)
        Baseline.Car.FuelFigures.mpg!(fuel, 40.0)
        Baseline.Car.FuelFigures.usageDescription!(fuel, "")
        
        # Empty string should still have 4-byte length header with 0 length
        header_size = 8
        message_block = SBE.sbe_block_length(car_enc)
        # dimension (4) + speed (2) + mpg (4) + vardata_header (4) + vardata_content (0)
        expected_pos = header_size + message_block + 4 + 6 + 4
        @test SBE.sbe_position(car_enc) == expected_pos
    end
    
    @testset "Shared AbstractSbeGroup Interface" begin
        buffer = zeros(UInt8, 512)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        
        # Test that shared methods work on any group type
        fuel = Baseline.Car.fuelFigures!(car_enc, 2)
        
        # Test shared methods from AbstractSbeGroup
        @test SBE.sbe_header_size(fuel) == 4
        @test length(fuel) == 2
        @test !Base.isdone(fuel)
        
        # Verify position pointer is shared
        pos_ptr_fuel = SBE.sbe_position_ptr(fuel)
        pos_ptr_car = SBE.sbe_position_ptr(car_enc)
        @test pos_ptr_fuel === pos_ptr_car
        
        # Test on nested group
        perf = Baseline.Car.performanceFigures!(car_enc, 1)
        Baseline.Car.PerformanceFigures.next!(perf)
        Baseline.Car.PerformanceFigures.octaneRating!(perf, 95)
        
        accel = Baseline.Car.PerformanceFigures.acceleration!(perf, 3)
        @test SBE.sbe_header_size(accel) == 4
        @test length(accel) == 3
        @test accel isa SBE.AbstractSbeGroup
        
        # All groups share the same position pointer
        @test SBE.sbe_position_ptr(accel) === pos_ptr_car
    end
    
    @testset "Complex Scenario - All Features" begin
        buffer = zeros(UInt8, 1024)
        car_enc = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(car_enc, buffer, 0)
        
        # Test 1: FuelFigures with var data
        fuel = Baseline.Car.fuelFigures!(car_enc, 2)
        
        Baseline.Car.FuelFigures.next!(fuel)
        Baseline.Car.FuelFigures.speed!(fuel, 55)
        Baseline.Car.FuelFigures.mpg!(fuel, 42.0)
        Baseline.Car.FuelFigures.usageDescription!(fuel, "City")
        
        Baseline.Car.FuelFigures.next!(fuel)
        Baseline.Car.FuelFigures.speed!(fuel, 75)
        Baseline.Car.FuelFigures.mpg!(fuel, 38.5)
        Baseline.Car.FuelFigures.usageDescription!(fuel, "Highway")
        
        # Test 2: PerformanceFigures with nested Acceleration
        perf = Baseline.Car.performanceFigures!(car_enc, 2)
        
        # First performance figure
        Baseline.Car.PerformanceFigures.next!(perf)
        Baseline.Car.PerformanceFigures.octaneRating!(perf, 95)
        accel1 = Baseline.Car.PerformanceFigures.acceleration!(perf, 3)
        
        Baseline.Car.PerformanceFigures.Acceleration.next!(accel1)
        Baseline.Car.PerformanceFigures.Acceleration.mph!(accel1, 30)
        Baseline.Car.PerformanceFigures.Acceleration.seconds!(accel1, 4.0)
        
        Baseline.Car.PerformanceFigures.Acceleration.next!(accel1)
        Baseline.Car.PerformanceFigures.Acceleration.mph!(accel1, 60)
        Baseline.Car.PerformanceFigures.Acceleration.seconds!(accel1, 7.5)
        
        Baseline.Car.PerformanceFigures.Acceleration.next!(accel1)
        Baseline.Car.PerformanceFigures.Acceleration.mph!(accel1, 100)
        Baseline.Car.PerformanceFigures.Acceleration.seconds!(accel1, 13.2)
        
        # Second performance figure
        Baseline.Car.PerformanceFigures.next!(perf)
        Baseline.Car.PerformanceFigures.octaneRating!(perf, 99)
        accel2 = Baseline.Car.PerformanceFigures.acceleration!(perf, 2)
        
        Baseline.Car.PerformanceFigures.Acceleration.next!(accel2)
        Baseline.Car.PerformanceFigures.Acceleration.mph!(accel2, 30)
        Baseline.Car.PerformanceFigures.Acceleration.seconds!(accel2, 3.5)
        
        Baseline.Car.PerformanceFigures.Acceleration.next!(accel2)
        Baseline.Car.PerformanceFigures.Acceleration.mph!(accel2, 60)
        Baseline.Car.PerformanceFigures.Acceleration.seconds!(accel2, 6.8)
        
        # Verify all groups are done
        @test Base.isdone(fuel)
        @test Base.isdone(perf)
        @test Base.isdone(accel1)
        @test Base.isdone(accel2)
        
        # Verify position advanced through all data
        final_pos = SBE.sbe_position(car_enc)
        @test final_pos > 100  # Should have written substantial data
        @test final_pos < 1024  # But within buffer bounds
    end
end
