using Test
using SBE

@testset "@load_schema Macro Tests" begin
    
    # Load Baseline schema once at the beginning for all tests
    @testset "Basic Macro Usage" begin
        # Test basic macro call with assignment
        schema_path = joinpath(@__DIR__, "example-schema.xml")
        @test isfile(schema_path)
        
        # Load schema using macro - should return module name as Symbol
        module_name = SBE.@load_schema schema_path
        @test module_name isa Symbol
        @test module_name == :Baseline
        
        # Module should be loaded in Main
        @test isdefined(Main, module_name)
        Baseline = getfield(Main, module_name)
        @test Baseline isa Module
    end
    
    # All subsequent tests reuse the already-loaded Baseline module
    @testset "Direct Module Access" begin
        # Baseline already loaded above - just verify access
        @test isdefined(Main, :Baseline)
        
        # Test that Car submodule exists
        @test isdefined(Baseline, :Car)
        @test Baseline.Car isa Module
        
        # Test that Decoder and Encoder types exist
        @test isdefined(Baseline.Car, :Decoder)
        @test isdefined(Baseline.Car, :Encoder)
        @test Baseline.Car.Decoder <: SBE.AbstractSbeMessage
        @test Baseline.Car.Encoder <: SBE.AbstractSbeMessage
    end
    
    @testset "No World Age Issues" begin
        # Baseline already loaded - test immediate use
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(buffer, 0)
        decoder = Baseline.Car.Decoder(buffer, 0)
        
        @test encoder isa Baseline.Car.Encoder
        @test decoder isa Baseline.Car.Decoder
        
        # Should be able to call methods immediately
        @test Baseline.Car.modelYear(decoder) isa UInt16
        Baseline.Car.modelYear!(encoder, UInt16(2024))
        @test Baseline.Car.modelYear(decoder) == UInt16(2024)
    end
    
    @testset "Field Access Functions" begin
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(buffer, 0)
        decoder = Baseline.Car.Decoder(buffer, 0)
        
        # Test various field types
        
        # Scalar field (serialNumber is UInt64 in the schema)
        @test hasmethod(Baseline.Car.serialNumber, Tuple{typeof(decoder)})
        @test hasmethod(Baseline.Car.serialNumber!, Tuple{typeof(encoder), UInt64})
        @test Baseline.Car.serialNumber(decoder) isa UInt64
        
        # Year field
        @test hasmethod(Baseline.Car.modelYear, Tuple{typeof(decoder)})
        @test hasmethod(Baseline.Car.modelYear!, Tuple{typeof(encoder), UInt16})
        @test Baseline.Car.modelYear(decoder) isa UInt16
        
        # Array field
        @test hasmethod(Baseline.Car.someNumbers, Tuple{typeof(decoder)})
        @test hasmethod(Baseline.Car.someNumbers!, Tuple{typeof(encoder), Any})
        numbers = Baseline.Car.someNumbers(decoder)
        @test numbers isa AbstractVector{UInt32}
        @test length(numbers) == 4
        
        # Boolean field (enum setter takes specific enum type, not Any)
        @test hasmethod(Baseline.Car.available, Tuple{typeof(decoder)})
        @test hasmethod(Baseline.Car.available!, Tuple{typeof(encoder), Baseline.BooleanType.SbeEnum})
        @test Baseline.Car.available(decoder) isa Baseline.BooleanType.SbeEnum
    end
    
    @testset "Metadata Functions" begin
        # Test that metadata functions exist (as functions in file-based generation)
        @test isdefined(Baseline.Car, :modelYear_encoding_offset)
        @test isdefined(Baseline.Car, :modelYear_encoding_length)
        @test isdefined(Baseline.Car, :modelYear_id)
        @test isdefined(Baseline.Car, :modelYear_since_version)
        
        # Test that they return correct types (using type dispatch)
        @test Baseline.Car.modelYear_encoding_offset(Baseline.Car.Decoder) isa Integer
        @test Baseline.Car.modelYear_encoding_length(Baseline.Car.Decoder) isa Integer
        @test Baseline.Car.modelYear_id(Baseline.Car.Decoder) isa UInt16
        @test Baseline.Car.modelYear_since_version(Baseline.Car.Decoder) isa UInt16
        
        # Test values are reasonable
        @test Baseline.Car.modelYear_encoding_offset(Baseline.Car.Decoder) >= 0
        @test Baseline.Car.modelYear_encoding_length(Baseline.Car.Decoder) > 0
        @test Baseline.Car.modelYear_since_version(Baseline.Car.Decoder) >= 0
    end
    
    @testset "Composite Types" begin
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(buffer, 0)
        decoder = Baseline.Car.Decoder(buffer, 0)
        
        # Test that composite field exists (Engine is a composite)
        @test hasmethod(Baseline.Car.engine, Tuple{typeof(decoder)})
        @test hasmethod(Baseline.Car.engine, Tuple{typeof(encoder)})
        
        engine_decoder = Baseline.Car.engine(decoder)
        engine_encoder = Baseline.Car.engine(encoder)
        
        @test engine_decoder isa Baseline.Engine.EngineStruct
        @test engine_encoder isa Baseline.Engine.EngineStruct
        
        # Test composite field accessors
        @test hasmethod(Baseline.Engine.capacity, Tuple{typeof(engine_decoder)})
        @test hasmethod(Baseline.Engine.capacity!, Tuple{typeof(engine_encoder), UInt16})
        
        # Test we can read/write through composite
        Baseline.Engine.capacity!(engine_encoder, UInt16(2000))
        @test Baseline.Engine.capacity(engine_decoder) == UInt16(2000)
    end
    
    @testset "Enum Types" begin
        # Test that enum module exists
        @test isdefined(Baseline, :BooleanType)
        @test Baseline.BooleanType isa Module
        
        # Test enum type
        @test isdefined(Baseline.BooleanType, :SbeEnum)
        @test Baseline.BooleanType.SbeEnum <: Enum
        
        # Test enum values
        @test isdefined(Baseline.BooleanType, :T)
        @test isdefined(Baseline.BooleanType, :F)
        
        @test Baseline.BooleanType.T isa Baseline.BooleanType.SbeEnum
        @test Baseline.BooleanType.F isa Baseline.BooleanType.SbeEnum
        
        # Test enum has correct underlying values
        @test UInt8(Baseline.BooleanType.T) == 0x01
        @test UInt8(Baseline.BooleanType.F) == 0x00
    end
    
    @testset "Groups" begin
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(buffer, 0)
        decoder = Baseline.Car.Decoder(buffer, 0)
        
        # Test that group accessor exists (decoder only in file-based generation)
        @test hasmethod(Baseline.Car.fuelFigures, Tuple{typeof(decoder)})
        
        # Get group - returns a Decoder type
        group_decoder = Baseline.Car.fuelFigures(decoder)
        @test group_decoder isa Baseline.Car.FuelFigures.Decoder
    end
    
    @testset "Variable Length Data" begin
        buffer = zeros(UInt8, 2048)
        encoder = Baseline.Car.Encoder(buffer, 0)
        decoder = Baseline.Car.Decoder(buffer, 0)
        
        # Test that vardata accessor exists
        @test hasmethod(Baseline.Car.manufacturer, Tuple{typeof(decoder)})
        @test hasmethod(Baseline.Car.manufacturer!, Tuple{typeof(encoder), AbstractString})
        
        # Test we can write and read (returns byte vector in file-based generation)
        test_string = "TestManufacturer"
        Baseline.Car.manufacturer!(encoder, test_string)
        result = Baseline.Car.manufacturer(decoder)
        # Result is a byte vector, convert for comparison
        @test String(result) == test_string
    end
    
    @testset "Multiple Schema Loading" begin
        # Test that calling @load_schema on already-loaded schema returns same module
        schema_path = joinpath(@__DIR__, "example-schema.xml")
        
        # Get reference to existing module
        mod1 = Main.Baseline
        
        # Load again - should return existing module (may warn about redefinition)
        name2 = SBE.@load_schema schema_path
        @test name2 == :Baseline
        
        # Should reference the same module (not create a new one)
        mod2 = getfield(Main, name2)
        @test mod1 === mod2
    end
    
    @testset "Different Schema Files" begin
        # Baseline already loaded above
        @test isdefined(Main, :Baseline)
        
        # Load extension schema (different package name)
        extension_path = joinpath(@__DIR__, "example-extension-schema.xml")
        extension_name = SBE.@load_schema extension_path
        @test extension_name == :Extension
        @test isdefined(Main, :Extension)
        
        # Both should coexist
        @test isdefined(Main, :Baseline)
        @test isdefined(Main, :Extension)
        
        # Both should have Car types
        @test isdefined(Baseline, :Car)
        @test isdefined(Extension, :Car)
        
        # But they should be different types
        @test Baseline.Car !== Extension.Car
    end
    
    @testset "Macro Without Assignment" begin
        # Test that macro works without capturing return value
        # Using Extension schema since it's already loaded
        SBE.@load_schema joinpath(@__DIR__, "example-extension-schema.xml")
        
        # Module should still be accessible
        @test isdefined(Main, :Extension)
        
        # Should still work
        buffer = zeros(UInt8, 1024)
        car = Extension.Car.Encoder(buffer, 0)
        @test car isa Extension.Car.Encoder
    end
    
    @testset "Generated Code Quality" begin
        buffer = zeros(UInt8, 1024)
        encoder = Baseline.Car.Encoder(buffer, 0)
        decoder = Baseline.Car.Decoder(buffer, 0)
        
        # Test that generated code has proper type annotations
        # File-based generation uses minimal fields
        @test fieldnames(typeof(encoder)) == (:buffer, :offset, :position_ptr)
        
        # Test buffer access
        @test Baseline.Car.sbe_buffer(encoder) === buffer
        # Offset advances after message header
        @test Baseline.Car.sbe_offset(encoder) >= 0
        
        # Test template metadata (takes message instance in file-based generation)
        @test Baseline.Car.sbe_template_id(encoder) isa Integer
        @test Baseline.Car.sbe_schema_id(encoder) isa Integer
        @test Baseline.Car.sbe_block_length(encoder) isa Integer
    end
    
    @testset "Error Handling" begin
        # Test with non-existent file
        @test_throws SystemError SBE.@load_schema "non_existent_file.xml"
        
        # Test with invalid XML path
        @test_throws Exception SBE.@load_schema "invalid/path/schema.xml"
    end
end
