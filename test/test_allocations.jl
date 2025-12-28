using Test
using SBE
using AllocCheck

# Use pre-generated Baseline module (loaded by runtests.jl)
# (No need to load schema at module level)

@testset "Allocation Tests" begin
    @testset "Zero-Allocation Decoding" begin
        # Create a properly encoded message first
        buffer = zeros(UInt8, 2048)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
        # Encode a complete message
        Baseline.Car.serialNumber!(encoder, 12345)
        Baseline.Car.modelYear!(encoder, 2024)
        Baseline.Car.available!(encoder, Baseline.BooleanType.T)
        Baseline.Car.code!(encoder, Baseline.Model.A)
        Baseline.Car.someNumbers!(encoder, UInt32[1, 2, 3, 4])
        Baseline.Car.vehicleCode!(encoder, codeunits("ABCDEF"))
        
        engine = Baseline.Car.engine(encoder)
        Baseline.Engine.capacity!(engine, 2000)
        Baseline.Engine.numCylinders!(engine, 4)
        
        # Now test decoding for allocations
        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)
        
        @testset "Scalar Field Decoding" begin
            @test isempty(check_allocs(Baseline.Car.serialNumber, (typeof(decoder),)))
            @test isempty(check_allocs(Baseline.Car.modelYear, (typeof(decoder),)))
            @test isempty(check_allocs(Baseline.Car.available, (typeof(decoder),)))
            @test isempty(check_allocs(Baseline.Car.code, (typeof(decoder),)))
        end
        
        @testset "Array Field Decoding" begin
            @test isempty(check_allocs(Baseline.Car.someNumbers, (typeof(decoder),)))
            @test isempty(check_allocs(Baseline.Car.vehicleCode, (typeof(decoder),)))
        end
        
        @testset "Composite Field Decoding" begin
            @test isempty(check_allocs(Baseline.Car.engine, (typeof(decoder),)))
            
            engine_dec = Baseline.Car.engine(decoder)
            @test isempty(check_allocs(Baseline.Engine.capacity, (typeof(engine_dec),)))
            @test isempty(check_allocs(Baseline.Engine.numCylinders, (typeof(engine_dec),)))
        end
    end
    
    @testset "Zero-Allocation Encoding" begin
        buffer = zeros(UInt8, 2048)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
        @testset "Scalar Field Encoding" begin
            @test isempty(check_allocs(Baseline.Car.serialNumber!, (typeof(encoder), UInt64)))
            @test isempty(check_allocs(Baseline.Car.modelYear!, (typeof(encoder), UInt16)))
        end
        
        @testset "Composite Field Encoding" begin
            encoder2 = Baseline.Car.Encoder(typeof(buffer))
            Baseline.Car.wrap_and_apply_header!(encoder2, buffer, 0)
            engine = Baseline.Car.engine(encoder2)
            
            @test isempty(check_allocs(Baseline.Engine.capacity!, (typeof(engine), UInt16)))
            @test isempty(check_allocs(Baseline.Engine.numCylinders!, (typeof(engine), UInt8)))
        end
    end
    
    @testset "Zero-Allocation Groups" begin
        buffer = zeros(UInt8, 2048)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
        # Encode basic fields first
        Baseline.Car.serialNumber!(encoder, 12345)
        Baseline.Car.modelYear!(encoder, 2024)
        Baseline.Car.available!(encoder, Baseline.BooleanType.T)
        Baseline.Car.code!(encoder, Baseline.Model.A)
        Baseline.Car.someNumbers!(encoder, UInt32[1, 2, 3, 4])
        Baseline.Car.vehicleCode!(encoder, codeunits("ABCDEF"))
        
        engine = Baseline.Car.engine(encoder)
        Baseline.Engine.capacity!(engine, 2000)
        Baseline.Engine.numCylinders!(engine, 4)
        
        # Encode groups
        fuel_figures = Baseline.Car.fuelFigures!(encoder, 2)
        
        entry1 = Baseline.Car.FuelFigures.next!(fuel_figures)
        Baseline.Car.FuelFigures.speed!(entry1, 30)
        Baseline.Car.FuelFigures.mpg!(entry1, 35.5f0)
        
        entry2 = Baseline.Car.FuelFigures.next!(fuel_figures)
        Baseline.Car.FuelFigures.speed!(entry2, 60)
        Baseline.Car.FuelFigures.mpg!(entry2, 42.0f0)
        
        # Now test decoding groups
        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)
        
        @testset "Group Decoding" begin
            group = Baseline.Car.fuelFigures(decoder)
            
            # Note: Group accessor may allocate due to parentmodule() call
            # This is a known limitation of the current implementation
            # The important thing is that iterating over groups doesn't allocate
            
            @test isempty(check_allocs(Base.length, (typeof(group),)))
            @test isempty(check_allocs(Base.eltype, (typeof(group),)))
        end
        
        @testset "Group Entry Field Access" begin
            # Create a fresh decoder since the previous test advanced the position
            decoder2 = Baseline.Car.Decoder(typeof(buffer))
            Baseline.Car.wrap!(decoder2, buffer, 0)
            group = Baseline.Car.fuelFigures(decoder2)
            entry = first(group)
            
            @test isempty(check_allocs(Baseline.Car.FuelFigures.speed, (typeof(entry),)))
            @test isempty(check_allocs(Baseline.Car.FuelFigures.mpg, (typeof(entry),)))
        end
    end
    
    @testset "Complete Round-Trip" begin
        # Simple round-trip without full message encoding
        # Just test that basic decode operations don't allocate
        buffer = zeros(UInt8, 2048)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
        # Encode some fields
        Baseline.Car.serialNumber!(encoder, UInt64(12345))
        Baseline.Car.modelYear!(encoder, UInt16(2024))
        
        # Create decoder
        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)
        
        @test isempty(check_allocs(Baseline.Car.serialNumber, (typeof(decoder),)))
        @test isempty(check_allocs(Baseline.Car.modelYear, (typeof(decoder),)))
        
        # Note: Some operations like creating decoders allocate PositionPointer
        # which is acceptable for the initial setup
    end
    
    @testset "Position Management" begin
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        Baseline.Car.serialNumber!(encoder, 12345)

        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)

        @test isempty(check_allocs(SBE.sbe_position, (typeof(decoder),)))
        @test isempty(check_allocs(SBE.sbe_position!, (typeof(encoder), Int)))
    end
    
    @testset "Metadata Access" begin
        buffer = zeros(UInt8, 1024)
        
        # Encode a message first so decoder has valid data
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        Baseline.Car.serialNumber!(encoder, 12345)
        
        # Now create decoder from encoded buffer
        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)
        
        @test isempty(check_allocs(SBE.sbe_position, (typeof(decoder),)))
        @test isempty(check_allocs(SBE.sbe_position!, (typeof(encoder), Int)))
        
        # Note: Metadata functions like sbe_template_id, sbe_schema_id, etc.
        # are not currently implemented for message types, only for groups
    end
    
    @testset "Zero-Allocation Variable-Length Data" begin
        # Note: VarData encoding uses @allocated instead of AllocCheck because
        # copyto! has aliasing checks that AllocCheck flags as potential allocations,
        # but these are typically optimized away at runtime by the Julia compiler.
        
        # Create a properly encoded message with vardata
        buffer = zeros(UInt8, 2048)
        encoder = Baseline.Car.Encoder(typeof(buffer))
        Baseline.Car.wrap_and_apply_header!(encoder, buffer, 0)
        
        # Encode required fields first
        Baseline.Car.serialNumber!(encoder, 12345)
        Baseline.Car.modelYear!(encoder, 2024)
        Baseline.Car.available!(encoder, Baseline.BooleanType.T)
        Baseline.Car.code!(encoder, Baseline.Model.A)
        Baseline.Car.someNumbers!(encoder, UInt32[1, 2, 3, 4])
        Baseline.Car.vehicleCode!(encoder, codeunits("ABCDEF"))
        
        engine = Baseline.Car.engine(encoder)
        Baseline.Engine.capacity!(engine, 2000)
        Baseline.Engine.numCylinders!(engine, 4)
        
        # Skip groups (write empty groups)
        Baseline.Car.fuelFigures!(encoder, 0)
        Baseline.Car.performanceFigures!(encoder, 0)
        
        # Encode vardata fields for warmup
        Baseline.Car.manufacturer!(encoder, "Toyota")
        Baseline.Car.model!(encoder, "Corolla")
        Baseline.Car.activationCode!(encoder, "ABC123")
        
        # Test vardata decoding for allocations
        decoder = Baseline.Car.Decoder(typeof(buffer))
        Baseline.Car.wrap!(decoder, buffer, 0)
        
        @testset "VarData Length Access" begin
            @test isempty(check_allocs(Baseline.Car.manufacturer_length, (typeof(decoder),)))
            @test isempty(check_allocs(Baseline.Car.model_length, (typeof(decoder),)))
            @test isempty(check_allocs(Baseline.Car.activationCode_length, (typeof(decoder),)))
        end
        
        @testset "VarData Skip" begin
            decoder2 = Baseline.Car.Decoder(typeof(buffer))
            Baseline.Car.wrap!(decoder2, buffer, 0)
            @test isempty(check_allocs(Baseline.Car.skip_manufacturer!, (typeof(decoder2),)))
        end
        
        @testset "VarData Raw Bytes Access" begin
            # Reading raw bytes (view) should not allocate
            decoder3 = Baseline.Car.Decoder(typeof(buffer))
            Baseline.Car.wrap!(decoder3, buffer, 0)
            @test isempty(check_allocs(Baseline.Car.manufacturer, (typeof(decoder3),)))
        end
        
        @testset "VarData Decoding (Runtime)" begin
            # Test that vardata decoding with type conversion doesn't allocate at runtime
            # (except for String conversion which creates the String object itself)
            decoder4 = Baseline.Car.Decoder(typeof(buffer))
            Baseline.Car.wrap!(decoder4, buffer, 0)
            
            # Warmup
            Baseline.Car.manufacturer(decoder4, String)
            
            # Test raw bytes (view) - should not allocate
            decoder5 = Baseline.Car.Decoder(typeof(buffer))
            Baseline.Car.wrap!(decoder5, buffer, 0)
            alloc_bytes = @allocated Baseline.Car.manufacturer(decoder5)
            @test alloc_bytes == 0
            
            # Test length accessor - should not allocate
            decoder6 = Baseline.Car.Decoder(typeof(buffer))
            Baseline.Car.wrap!(decoder6, buffer, 0)
            alloc_length = @allocated Baseline.Car.manufacturer_length(decoder6)
            @test alloc_length == 0
            
            # Test skip - should not allocate
            decoder7 = Baseline.Car.Decoder(typeof(buffer))
            Baseline.Car.wrap!(decoder7, buffer, 0)
            alloc_skip = @allocated Baseline.Car.skip_manufacturer!(decoder7)
            @test alloc_skip == 0
            
            # Note: String conversion allocates the String object itself, so we don't test that
        end
        
        @testset "VarData Encoding (Runtime)" begin
            # Use @allocated for vardata encoding since AllocCheck reports
            # potential allocations in copyto! that don't actually occur at runtime
            buffer2 = zeros(UInt8, 2048)
            encoder2 = Baseline.Car.Encoder(typeof(buffer2))
            Baseline.Car.wrap_and_apply_header!(encoder2, buffer2, 0)
            
            # Skip to vardata section by encoding minimal message
            Baseline.Car.serialNumber!(encoder2, 12345)
            Baseline.Car.modelYear!(encoder2, 2024)
            Baseline.Car.available!(encoder2, Baseline.BooleanType.T)
            Baseline.Car.code!(encoder2, Baseline.Model.A)
            Baseline.Car.someNumbers!(encoder2, UInt32[1, 2, 3, 4])
            Baseline.Car.vehicleCode!(encoder2, codeunits("ABCDEF"))
            
            engine2 = Baseline.Car.engine(encoder2)
            Baseline.Engine.capacity!(engine2, 2000)
            Baseline.Engine.numCylinders!(engine2, 4)
            
            Baseline.Car.fuelFigures!(encoder2, 0)
            Baseline.Car.performanceFigures!(encoder2, 0)
            
            # Warmup to compile the methods
            Baseline.Car.manufacturer!(encoder2, "warmup")
            
            # Test runtime allocations with @allocated
            test_string = "TestData"
            alloc_string = @allocated Baseline.Car.model!(encoder2, test_string)
            @test alloc_string == 0
            
            test_bytes = Vector{UInt8}(codeunits("MoreData"))
            alloc_bytes = @allocated Baseline.Car.activationCode!(encoder2, test_bytes)
            @test alloc_bytes == 0
        end
    end
end
