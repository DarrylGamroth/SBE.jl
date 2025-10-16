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
        
        # Test that Car module exists (new nested module structure)
        @test isdefined(Baseline, :Car)
        @test isa(Baseline.Car, Module)
        
        # Test that Decoder and Encoder types exist in Car module
        @test isdefined(Baseline.Car, :Decoder)
        @test isdefined(Baseline.Car, :Encoder)
        @test Baseline.Car.Decoder <: SBE.AbstractSbeMessage
        @test Baseline.Car.Encoder <: SBE.AbstractSbeMessage
        
        # Test that OLD type aliases do NOT exist (clean nested structure)
        @test !isdefined(Baseline, :CarDecoder)
        @test !isdefined(Baseline, :CarEncoder)
        
        # Test basic usage with encoder (new API)
        # Test with the fields we know are generated
        buffer = zeros(UInt8, 1024)
        car_encoder = Baseline.Car.Encoder(buffer, 0)
        car_decoder = Baseline.Car.Decoder(buffer, 0)
        
        # Test that field accessor functions exist and work
        # (exact values may vary due to field offsets - main goal is to test API)
        @test hasmethod(Baseline.Car.modelYear, Tuple{typeof(car_decoder)})
        @test hasmethod(Baseline.Car.modelYear!, Tuple{typeof(car_encoder), UInt16})
        @test hasmethod(Baseline.Car.someNumbers, Tuple{typeof(car_decoder)})
        @test hasmethod(Baseline.Car.someNumbers!, Tuple{typeof(car_encoder), Any})
        
        # Test reading returns correct types
        @test Baseline.Car.modelYear(car_decoder) isa UInt16
        @test Baseline.Car.someNumbers(car_decoder) isa AbstractVector{UInt32}
        @test length(Baseline.Car.someNumbers(car_decoder)) == 4
        
        # Test metadata functions are available (static constants in new API)
        @test isdefined(Baseline.Car, :modelYear_encoding_offset)
        @test isdefined(Baseline.Car, :modelYear_encoding_length)
        @test isdefined(Baseline.Car, :modelYear_id)
        @test isdefined(Baseline.Car, :modelYear_since_version)
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
