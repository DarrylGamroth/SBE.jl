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
        
        # Load the module once
        include(output_file)
        
        # Verify module exists and has expected structure
        @test isdefined(Main, :Baseline)
        
        # Test enum functionality
        @test Main.Baseline.BooleanType.T isa Main.Baseline.BooleanType.SbeEnum
        @test Main.Baseline.BooleanType.F isa Main.Baseline.BooleanType.SbeEnum
        @test UInt8(Main.Baseline.BooleanType.T) == 0x01
        @test UInt8(Main.Baseline.BooleanType.F) == 0x00
        
        # Test composite type (Engine) functionality
        @test isdefined(Main.Baseline, :Engine)
        buffer = zeros(UInt8, 256)
        engine_enc = Main.Baseline.Engine.Encoder(buffer, 0)
        @test engine_enc isa Main.Baseline.Engine.Encoder
        
        # Test we can set and get values
        Main.Baseline.Engine.capacity!(engine_enc, UInt16(2000))
        Main.Baseline.Engine.numCylinders!(engine_enc, UInt8(4))
        
        engine_dec = Main.Baseline.Engine.Decoder(buffer, 0, UInt16(0))
        @test Main.Baseline.Engine.capacity(engine_dec) == UInt16(2000)
        @test Main.Baseline.Engine.numCylinders(engine_dec) == UInt8(4)
        
        # Test message encoding/decoding
        msg_buffer = zeros(UInt8, 512)
        car_enc = Main.Baseline.Car.Encoder(typeof(msg_buffer))
        Main.Baseline.Car.wrap_and_apply_header!(car_enc, msg_buffer, 0)
        @test car_enc isa Main.Baseline.Car.Encoder
        
        # Set field values
        Main.Baseline.Car.serialNumber!(car_enc, UInt64(12345))
        Main.Baseline.Car.modelYear!(car_enc, UInt16(2024))
        Main.Baseline.Car.available!(car_enc, Main.Baseline.BooleanType.T)
        Main.Baseline.Car.code!(car_enc, Main.Baseline.Model.A)
        
        # Decode and verify
        car_dec = Main.Baseline.Car.Decoder(typeof(msg_buffer))
        Main.Baseline.Car.wrap!(car_dec, msg_buffer, 0)
        @test Main.Baseline.Car.serialNumber(car_dec) == UInt64(12345)
        @test Main.Baseline.Car.modelYear(car_dec) == UInt16(2024)
        @test Main.Baseline.Car.available(car_dec) == Main.Baseline.BooleanType.T
        @test Main.Baseline.Car.code(car_dec) == Main.Baseline.Model.A
        
        # Clean up file
        rm(output_file, force=true)
    end
    
    # Test Extension schema
    @testset "Extension schema generation" begin
        code = SBE.generate(joinpath(@__DIR__, "example-extension-schema.xml"))
        
        @test code isa String
        @test length(code) > 0
        
        # Load with include_string
        Base.include_string(Main, code)
        
        # Verify module exists
        @test isdefined(Main, :Extension)
        
        # Test actual functionality - can encode/decode
        buffer = zeros(UInt8, 512)
        encoder = Main.Extension.Car.Encoder(typeof(buffer))
        Main.Extension.Car.wrap_and_apply_header!(encoder, buffer, 0)
        @test encoder isa Main.Extension.Car.Encoder
        
        # Set and verify a value
        Main.Extension.Car.serialNumber!(encoder, UInt64(54321))
        decoder = Main.Extension.Car.Decoder(typeof(buffer))
        Main.Extension.Car.wrap!(decoder, buffer, 0)
        @test Main.Extension.Car.serialNumber(decoder) == UInt64(54321)
    end
    
    # Test Optional schema
    @testset "Optional schema (@load_schema macro)" begin
        module_name = SBE.@load_schema joinpath(@__DIR__, "example-optional-schema.xml")
        
        @test module_name == :Optional
        @test isdefined(Main, module_name)
        
        # Test actual functionality - can encode/decode Order message
        buffer = zeros(UInt8, 512)
        encoder = Main.Optional.Order.Encoder(typeof(buffer))
        Main.Optional.Order.wrap_and_apply_header!(encoder, buffer, 0)
        @test encoder isa Main.Optional.Order.Encoder
        
        # Test required and optional field functionality
        Main.Optional.Order.orderId!(encoder, UInt64(12345))
        Main.Optional.Order.quantity!(encoder, UInt32(100))
        decoder = Main.Optional.Order.Decoder(typeof(buffer))
        Main.Optional.Order.wrap!(decoder, buffer, 0)
        @test Main.Optional.Order.orderId(decoder) == UInt64(12345)
        @test Main.Optional.Order.quantity(decoder) == UInt32(100)
    end
    
    # Test Versioned schema
    @testset "Versioned schema generation" begin
        # Test that generated code is valid Julia syntax
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
            
            # Module already loaded from include_string above
            @test isdefined(Main, :Versioned)
            @test isdefined(Main.Versioned, :Product)  # Versioned schema has Product message
            
            # Test version handling - encode and decode
            buffer = zeros(UInt8, 512)
            encoder = Main.Versioned.Product.Encoder(typeof(buffer))
            Main.Versioned.Product.wrap_and_apply_header!(encoder, buffer, 0)
            @test encoder isa Main.Versioned.Product.Encoder
            
            # Set base version fields and verify
            Main.Versioned.Product.id!(encoder, UInt64(99))
            Main.Versioned.Product.quantity!(encoder, UInt32(42))
            decoder = Main.Versioned.Product.Decoder(typeof(buffer))
            Main.Versioned.Product.wrap!(decoder, buffer, 0)
            @test Main.Versioned.Product.id(decoder) == UInt64(99)
            @test Main.Versioned.Product.quantity(decoder) == UInt32(42)
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
