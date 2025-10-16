using Test
using SBE
using SBE.Schema
using EnumX

# Import the codegen utils directly
include("../src/codegen_utils.jl")

@testset "Simple Enum Generation Tests" begin
    # Load schema for testing - this returns the generated module
    schema_path = joinpath(@__DIR__, "example-schema.xml")
    baseline_module = load_schema(schema_path)
    
    @testset "BooleanType Enum Generation" begin
        # Test that BooleanType was generated in the baseline module
        @test isdefined(baseline_module, :BooleanType)
        
        # Get the generated enum module
        BooleanTypeModule = getfield(baseline_module, :BooleanType)
        @test BooleanTypeModule isa Module
        
        # The actual enum type is SbeEnum inside the module
        BooleanType = BooleanTypeModule.SbeEnum
        
        # Test enum structure
        @test BooleanType isa Type
        @test supertype(BooleanType) <: EnumX.Enum  # EnumX creates enums that inherit from Enum
        
        # Test enum values exist
        @test isdefined(BooleanTypeModule, :F)
        @test isdefined(BooleanTypeModule, :T)
        @test isdefined(BooleanTypeModule, :NULL_VALUE)
        
        # Test enum values are correct type
        @test BooleanTypeModule.F isa BooleanType
        @test BooleanTypeModule.T isa BooleanType
        @test BooleanTypeModule.NULL_VALUE isa BooleanType
        
        # Test that we can convert to underlying type
        @test UInt8(BooleanTypeModule.F) isa UInt8
        @test UInt8(BooleanTypeModule.T) isa UInt8
        @test UInt8(BooleanTypeModule.NULL_VALUE) isa UInt8
        
        # Test specific values match expectations
        @test UInt8(BooleanTypeModule.F) == 0    # False = 0
        @test UInt8(BooleanTypeModule.T) == 1    # True = 1
        @test UInt8(BooleanTypeModule.NULL_VALUE) == 255  # NULL = typemax(UInt8)
    end
    
    @testset "Model Enum Generation" begin
        # Test that Model was generated in the baseline module
        @test isdefined(baseline_module, :Model)
        
        # Get the generated enum module
        ModelModule = getfield(baseline_module, :Model)
        @test ModelModule isa Module
        
        # The actual enum type is SbeEnum inside the module
        Model = ModelModule.SbeEnum
        
        # Test enum structure
        @test Model isa Type
        @test supertype(Model) <: EnumX.Enum
        
        # Test enum values exist (Model should have A, B, C values)
        @test isdefined(ModelModule, :A)
        @test isdefined(ModelModule, :B) 
        @test isdefined(ModelModule, :C)
        @test isdefined(ModelModule, :NULL_VALUE)
        
        # Test enum values are correct type
        @test ModelModule.A isa Model
        @test ModelModule.B isa Model
        @test ModelModule.C isa Model
        @test ModelModule.NULL_VALUE isa Model
        
        # Test that we can convert to underlying type
        @test UInt8(ModelModule.A) isa UInt8
        @test UInt8(ModelModule.B) isa UInt8
        @test UInt8(ModelModule.C) isa UInt8
        @test UInt8(ModelModule.NULL_VALUE) == UInt8(0x0)  # Standard char null value
        
        # Test specific character values match ASCII encoding
        @test UInt8(ModelModule.A) == UInt8('A')  # A = 65
        @test UInt8(ModelModule.B) == UInt8('B')  # B = 66
        @test UInt8(ModelModule.C) == UInt8('C')  # C = 67
    end
end
