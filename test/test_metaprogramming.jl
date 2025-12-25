using Test
using SBE

@testset "SBE Metaprogramming Tests" begin
    
    @testset "Abstract Types" begin
        @test AbstractSbeMessage isa Type
        @test AbstractSbeField isa Type
        @test AbstractSbeGroup isa Type
        @test AbstractSbeData isa Type
        @test AbstractSbeEncodedType <: AbstractSbeField
        @test AbstractSbeCompositeType <: AbstractSbeField
    end
    
    @testset "Interface Functions" begin
        # Test that our interface functions are defined
        @test isdefined(SBE, :id)
        @test isdefined(SBE, :since_version)
        @test isdefined(SBE, :in_acting_version)
        @test isdefined(SBE, :encoding_offset)
        @test isdefined(SBE, :encoding_length)
        @test isdefined(SBE, :null_value)
        @test isdefined(SBE, :min_value)
        @test isdefined(SBE, :max_value)
    end
    
    @testset "XML Integration" begin
        # Test XML parsing with real schema
        schema_path = joinpath(@__DIR__, "example-schema.xml")
        @test isfile(schema_path)
        
        # Parse the schema
        xml_content = read(schema_path, String)
        schema = parse_sbe_schema(xml_content)
        
        @test schema isa SBE.XmlMessageSchema
        @test schema.id == 1
        @test schema.version == 0
        @test schema.package_name == "baseline"
        @test schema.byte_order == :littleEndian
        
        # Check that types and messages were parsed
        @test length(schema.types_by_name) > 0
        @test length(schema.messages) > 0
    end
    @testset "Meta Attribute Functions" begin
        # Test meta attribute function with pre-generated schema
        # The Baseline module is loaded in runtests.jl
        
        # Meta attributes in the new API are accessed through metadata constants
        # For field presence, all fields are "required" by default in the schema
        # Individual metadata is accessed via the field-specific constants (functions)
        @test isdefined(Baseline.Car, :modelYear_id)
        @test isdefined(Baseline.Car, :modelYear_since_version)
        @test Baseline.Car.modelYear_id(Baseline.Car.Decoder) isa UInt16
        @test Baseline.Car.modelYear_since_version(Baseline.Car.Decoder) isa UInt16
        
        # Schema object tests are covered in IR and XML parsing tests.
    end
end
