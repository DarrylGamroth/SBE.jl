using Test
using SBE

@testset "Schema Loading Tests" begin
    
    @testset "Load Baseline Schema" begin
        # Load the baseline schema
        schema_path = joinpath(@__DIR__, "example-schema.xml")
        @test isfile(schema_path)
        
        # Load schema should create a Baseline module
        Baseline = SBE.load_schema(schema_path)
        
        # Test that we got a module
        @test isa(Baseline, Module)
        
        # Test that Car type exists and has correct hierarchy
        @test isdefined(Baseline, :Car)
        @test Baseline.Car <: SBE.AbstractSbeMessage
        
        # Test that field types exist
        @test isdefined(Baseline, :ModelYear)
        @test isdefined(Baseline, :SomeNumbers)
        @test isdefined(Baseline, :VehicleCode)
        
        # Test field type hierarchy
        @test Baseline.ModelYear <: SBE.AbstractSbeEncodedType
        @test Baseline.SomeNumbers <: SBE.AbstractSbeEncodedType
        @test Baseline.VehicleCode <: SBE.AbstractSbeEncodedType
        
        # Test basic usage
        buffer = zeros(UInt8, 1024)
        car = Baseline.Car(buffer, 0)
        
        # Test field creation
        model_year = Baseline.ModelYear(car)
        some_numbers = Baseline.SomeNumbers(car)
        vehicle_code = Baseline.VehicleCode(car)
        
        # Test interface functions work
        @test SBE.id(model_year) isa UInt16
        @test SBE.encoding_offset(model_year) isa Int
        @test SBE.encoding_length(model_year) isa Int
        
        # Test value accessors
        @test SBE.value(model_year) isa UInt16
        SBE.value!(model_year, UInt16(2024))
        @test SBE.value(model_year) == UInt16(2024)
        
        # Test array field
        @test SBE.value(some_numbers) isa AbstractVector{UInt32}
        @test length(SBE.value(some_numbers)) == 4
        
        # Test meta attributes
        @test SBE.meta_attribute(car, :presence) == Symbol("required")
        @test SBE.meta_attribute(car, :unknown) == Symbol("")
    end
    
    @testset "Multiple Schemas" begin
        # Test that we can load multiple schemas without conflicts
        # For now, just test loading the same schema twice creates separate modules
        schema_path = joinpath(@__DIR__, "example-schema.xml")
        
        Baseline1 = SBE.load_schema(schema_path)
        Baseline2 = SBE.load_schema(schema_path)
        
        # Should be the same module (same package name)
        @test Baseline1 === Baseline2
        
        # Both should have the same types
        @test isdefined(Baseline1, :Car)
        @test isdefined(Baseline2, :Car)
        @test Baseline1.Car === Baseline2.Car
    end
end
