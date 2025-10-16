using Test
using SBE
using SBE.Schema
using EnumX

@testset "Generated Enum Validation Tests" begin
    # Load schema to trigger enum generation
    schema_path = joinpath(@__DIR__, "example-schema.xml")
    baseline_module = load_schema(schema_path)
    
    @testset "BooleanType Enum Validation" begin
        # Test that BooleanType was generated in the baseline module
        @test isdefined(baseline_module, :BooleanType)
        
        # Get the generated enum type
        BooleanType = getfield(baseline_module, :BooleanType)
        
        # Test enum structure
        @test BooleanType isa Type
        @test supertype(BooleanType) <: EnumX.Enum
        
        # Test enum values exist
        @test isdefined(BooleanType, :F)
        @test isdefined(BooleanType, :T)
        @test isdefined(BooleanType, :NULL_VALUE)
        
        # Test enum values are correct type (UInt8)
        @test BooleanType.F isa BooleanType
        @test BooleanType.T isa BooleanType
        @test BooleanType.NULL_VALUE isa BooleanType
        
        # Test that we can convert to underlying type
        @test UInt8(BooleanType.F) isa UInt8
        @test UInt8(BooleanType.T) isa UInt8
        @test UInt8(BooleanType.NULL_VALUE) isa UInt8
        
        # Test enum values are sensible
        @test UInt8(BooleanType.F) == UInt8(0)  # False should be 0
        @test UInt8(BooleanType.T) == UInt8(1)  # True should be 1  
        @test UInt8(BooleanType.NULL_VALUE) == UInt8(0xff)  # NULL_VALUE should be max for uint8
    end
    
    @testset "Model Enum Validation" begin
        # Test that Model was generated in the baseline module
        @test isdefined(baseline_module, :Model)
        
        # Get the generated enum type
        Model = getfield(baseline_module, :Model)
        
        # Test enum structure
        @test Model isa Type
        @test supertype(Model) <: EnumX.Enum
        
        # Test enum values exist (Model should have A, B, C values)
        @test isdefined(Model, :A)
        @test isdefined(Model, :B) 
        @test isdefined(Model, :C)
        @test isdefined(Model, :NULL_VALUE)
        
        # Test enum values are correct type (UInt8 for char encoding)
        @test Model.A isa Model
        @test Model.B isa Model
        @test Model.C isa Model
        @test Model.NULL_VALUE isa Model
        
        # Test that we can convert to underlying type
        @test UInt8(Model.A) isa UInt8
        @test UInt8(Model.B) isa UInt8
        @test UInt8(Model.C) isa UInt8
        @test UInt8(Model.NULL_VALUE) == UInt8(0x0)  # Standard char null value
        
        # Test enum values match expected character values
        @test UInt8(Model.A) == UInt8('A')  # 'A'
        @test UInt8(Model.B) == UInt8('B')  # 'B'
        @test UInt8(Model.C) == UInt8('C')  # 'C'
    end
end
