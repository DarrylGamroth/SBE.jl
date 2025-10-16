using Test
using SBE

@testset "Set Type Generation Tests" begin
    # Load schema that has set types
    schema_path = joinpath(@__DIR__, "example-schema.xml")
    baseline_module = SBE.load_schema(schema_path)
    
    @testset "Set Type Creation" begin
        # Test that OptionalExtras set type exists
        @test isdefined(baseline_module, :OptionalExtras)
        @test isdefined(baseline_module, :OptionalExtrasDecoder)
        @test isdefined(baseline_module, :OptionalExtrasEncoder)
        
        # Test type hierarchy
        OptionalExtras = getfield(baseline_module, :OptionalExtras)
        @test OptionalExtras <: SBE.AbstractSbeEncodedType
        
        # Test that decoder and encoder are aliases
        OptionalExtrasDecoder = getfield(baseline_module, :OptionalExtrasDecoder)
        OptionalExtrasEncoder = getfield(baseline_module, :OptionalExtrasEncoder)
        @test OptionalExtrasDecoder === OptionalExtras
        @test OptionalExtrasEncoder === OptionalExtras
    end
    
    @testset "Set Type Interface" begin
        # Create a test buffer
        buffer = zeros(UInt8, 64)
        
        # Create set instance
        OptionalExtras = getfield(baseline_module, :OptionalExtras)
        extras = OptionalExtras(buffer, 0)
        
        # Test SBE interface methods exist
        @test hasmethod(SBE.id, (typeof(extras),))
        @test hasmethod(SBE.since_version, (typeof(extras),))
        @test hasmethod(SBE.encoding_offset, (typeof(extras),))
        @test hasmethod(SBE.encoding_length, (typeof(extras),))
        @test hasmethod(Base.eltype, (typeof(extras),))
        
        # Test interface method values
        @test SBE.id(extras) isa UInt16
        @test SBE.since_version(extras) isa UInt16
        @test SBE.encoding_offset(extras) isa Int
        @test SBE.encoding_length(extras) == 1  # UInt8 size
        @test Base.eltype(extras) == UInt8
    end
    
    @testset "Set Operations" begin
        # Create a test buffer
        buffer = zeros(UInt8, 64)
        
        # Create set instance
        OptionalExtras = getfield(baseline_module, :OptionalExtras)
        extras = OptionalExtras(buffer, 0)
        
        # Test basic set operations exist
        @test hasmethod(baseline_module.clear!, (typeof(extras),))
        @test hasmethod(baseline_module.is_empty, (typeof(extras),))
        @test hasmethod(baseline_module.raw_value, (typeof(extras),))
        
        # Test initial state (should be empty after clear)
        baseline_module.clear!(extras)
        @test baseline_module.is_empty(extras)
        @test baseline_module.raw_value(extras) == 0x00
    end
    
    @testset "Choice Functions" begin
        # Create a test buffer
        buffer = zeros(UInt8, 64)
        
        # Create set instance
        OptionalExtras = getfield(baseline_module, :OptionalExtras)
        extras = OptionalExtras(buffer, 0)
        
        # Clear initial state
        baseline_module.clear!(extras)
        
        # Test choice functions exist (from schema: sunRoof(0), sportsPack(1), cruiseControl(2))
        @test hasmethod(baseline_module.sunRoof, (typeof(extras),))
        @test hasmethod(getfield(baseline_module, Symbol("sunRoof!")), (typeof(extras), Bool))
        @test hasmethod(baseline_module.sportsPack, (typeof(extras),))
        @test hasmethod(getfield(baseline_module, Symbol("sportsPack!")), (typeof(extras), Bool))
        @test hasmethod(baseline_module.cruiseControl, (typeof(extras),))
        @test hasmethod(getfield(baseline_module, Symbol("cruiseControl!")), (typeof(extras), Bool))
        
        # Test choice operations
        # Initially all should be false
        @test baseline_module.sunRoof(extras) == false
        @test baseline_module.sportsPack(extras) == false
        @test baseline_module.cruiseControl(extras) == false
        
        # Set sunRoof (bit 0)
        getfield(baseline_module, Symbol("sunRoof!"))(extras, true)
        @test baseline_module.sunRoof(extras) == true
        @test baseline_module.sportsPack(extras) == false
        @test baseline_module.cruiseControl(extras) == false
        @test baseline_module.raw_value(extras) == 0x01  # bit 0 set
        
        # Set sportsPack (bit 1)
        getfield(baseline_module, Symbol("sportsPack!"))(extras, true)
        @test baseline_module.sunRoof(extras) == true
        @test baseline_module.sportsPack(extras) == true
        @test baseline_module.cruiseControl(extras) == false
        @test baseline_module.raw_value(extras) == 0x03  # bits 0,1 set
        
        # Set cruiseControl (bit 2)
        getfield(baseline_module, Symbol("cruiseControl!"))(extras, true)
        @test baseline_module.sunRoof(extras) == true
        @test baseline_module.sportsPack(extras) == true
        @test baseline_module.cruiseControl(extras) == true
        @test baseline_module.raw_value(extras) == 0x07  # bits 0,1,2 set
        
        # Clear sportsPack (bit 1)
        getfield(baseline_module, Symbol("sportsPack!"))(extras, false)
        @test baseline_module.sunRoof(extras) == true
        @test baseline_module.sportsPack(extras) == false
        @test baseline_module.cruiseControl(extras) == true
        @test baseline_module.raw_value(extras) == 0x05  # bits 0,2 set
        
        # Clear all
        baseline_module.clear!(extras)
        @test baseline_module.is_empty(extras)
        @test baseline_module.sunRoof(extras) == false
        @test baseline_module.sportsPack(extras) == false
        @test baseline_module.cruiseControl(extras) == false
    end
end
