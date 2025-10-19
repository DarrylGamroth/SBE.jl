"""
Test file-based code generation

Tests the generate() function for creating standalone Julia files:
1. generate(xml, file) -> creates .jl file
2. generate(xml) -> returns code string
3. Validates generated code structure and usability

Note: Each schema is loaded only once to avoid module redefinition issues.
"""

using Test
using SBE

@testset "File-Based Generation Tests" begin
    # Generate baseline schema once and run multiple tests on it
    @testset "Baseline schema generation" begin
        # Test file-based generation
        output_file = tempname() * ".jl"
        result = SBE.generate(joinpath(@__DIR__, "example-schema.xml"), output_file)
        
        @test result == output_file
        @test isfile(output_file)
        @test filesize(output_file) > 0
        
        # Test string-based generation
        code = SBE.generate(joinpath(@__DIR__, "example-schema.xml"))
        @test code isa String
        @test length(code) > 0
        
        # Verify generated code structure
        @test occursin("module Baseline", code)
        @test occursin("@enumx T = SbeEnum BooleanType", code)
        @test occursin("@enumx T = SbeEnum", code)  # At least one enum
        @test occursin("module Engine", code)
        # Check for composite types (e.g., Engine, Booster) - now uses abstract type pattern
        @test occursin("abstract type AbstractEngine", code)
        @test occursin(r"struct Decoder.*<: AbstractEngine"s, code)
        @test occursin(r"struct Encoder.*<: AbstractEngine"s, code)
        @test occursin("module Car", code)
        @test occursin("struct Encoder", code)
        @test occursin("struct Decoder", code)
        @test occursin("function serialNumber", code)
        @test occursin("function modelYear!", code)
        
        # Load the module once
        include(output_file)
        
        # Verify module exists
        @test isdefined(Main, :Baseline)
        
        # Verify we can create instances
        buffer = zeros(UInt8, 256)
        encoder = Main.Baseline.Car.Encoder(buffer, 0)
        @test encoder isa Main.Baseline.Car.Encoder
        
        # Verify enum access (enums are at package level now, not wrapped in modules)
        @test Main.Baseline.BooleanType.T isa Main.Baseline.BooleanType.SbeEnum
        
        # Verify composite access
        @test isdefined(Main.Baseline, :Engine)
        
        # Clean up file
        rm(output_file, force=true)
    end
    
    # Test Extension schema
    @testset "Extension schema generation" begin
        code = SBE.generate(joinpath(@__DIR__, "example-extension-schema.xml"))
        
        @test code isa String
        @test length(code) > 0
        @test occursin("module Extension", code)
        @test occursin("@enumx T = SbeEnum BooleanType", code)
        
        # Load with include_string
        Base.include_string(Main, code)
        
        # Verify module exists
        @test isdefined(Main, :Extension)
        
        # Verify we can create instances
        buffer = zeros(UInt8, 256)
        encoder = Main.Extension.Car.Encoder(buffer, 0)
        @test encoder isa Main.Extension.Car.Encoder
    end
    
    # Test Optional schema
    @testset "Optional schema (@load_schema macro)" begin
        module_name = SBE.@load_schema joinpath(@__DIR__, "example-optional-schema.xml")
        
        @test module_name == :Optional
        @test isdefined(Main, module_name)
        
        # Verify we can create instances (Optional schema has Order message, not Car)
        buffer = zeros(UInt8, 256)
        encoder = Main.Optional.Order.Encoder(buffer, 0)
        @test encoder isa Main.Optional.Order.Encoder
    end
    
    # Test Versioned schema
    @testset "Versioned schema generation" begin
        # Test that generated code compiles without errors
        code = SBE.generate(joinpath(@__DIR__, "example-versioned-schema.xml"))
        
        # Parse the code (will throw if invalid syntax)
        expr = Meta.parse("begin\n" * code * "\nend")
        @test expr isa Expr
        
        # Load it
        Base.include_string(Main, code)
        @test isdefined(Main, :Versioned)
        
        # Test file-based generation
        output_file = tempname() * "_test_schema.jl"
        
        try
            result = SBE.generate(
                joinpath(@__DIR__, "example-versioned-schema.xml"),
                output_file
            )
            
            @test result == output_file
            @test isfile(output_file)
            @test filesize(output_file) > 1000  # Should be substantial
            
            # Verify file contents
            file_code = read(output_file, String)
            @test occursin("module Versioned", file_code)
            @test occursin("struct Encoder", file_code)
            @test occursin("struct Decoder", file_code)
            
            # Module already loaded from include_string above
            @test isdefined(Main, :Versioned)
            @test isdefined(Main.Versioned, :Product)  # Versioned schema has Product message
        finally
            rm(output_file, force=true)
        end
    end
    
    # Test multiple schemas have unique modules
    @testset "Multiple schemas have unique modules" begin
        # All schemas already loaded above, just verify they don't conflict
        @test isdefined(Main, :Baseline)
        @test isdefined(Main, :Extension)
        @test isdefined(Main, :Optional)
        @test isdefined(Main, :Versioned)
        
        # Each should be a different module
        @test Main.Baseline !== Main.Extension
        @test Main.Extension !== Main.Optional
        @test Main.Optional !== Main.Versioned
    end
end
