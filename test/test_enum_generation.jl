using Test
using SBE
using SBE.Schema
using EnumX

@testset "Enum Type Generation" begin
    @testset "BooleanType Enum Generation" begin
        # Create a test BooleanType enum definition (from example schema)
        boolean_enum = Schema.EnumType(
            "BooleanType",
            "uint8",
            [
                Schema.ValidValue("F", "0", "False value representation.", 0, nothing),
                Schema.ValidValue("T", "1", "True value representation.", 0, nothing)
            ],
            nothing, nothing, "Boolean Type.", 0, nothing
        )
        
        schema = Schema.MessageSchema(
            UInt16(1), UInt16(0), "5.2", "test", "littleEndian", "messageHeader",
            "Test schema for enum types",
            [boolean_enum],
            Schema.MessageDefinition[]
        )
        
        # Create a test module for generating the enum type
        test_module_name = Symbol("TestEnumModule")
        Core.eval(Main, :(module $test_module_name end))
        test_module = getfield(Main, test_module_name)
        
        # Import EnumX into the test module
        Core.eval(test_module, :(using EnumX))
        
        # Generate the enum type
        result = SBE.generate_complete_enum_type!(test_module, boolean_enum, schema)
        
        @test result == :BooleanType
        @test isdefined(test_module, :BooleanType)
        
        # Get the generated enum type
        BooleanType = getfield(test_module, :BooleanType)
        
        # Test enum structure
        @test BooleanType <: EnumX.Enum
        @test BooleanType.F isa BooleanType
        @test BooleanType.T isa BooleanType
        @test BooleanType.NULL_VALUE isa BooleanType
        
        # Test enum values
        @test UInt8(BooleanType.F) == 0x00
        @test UInt8(BooleanType.T) == 0x01
        @test UInt8(BooleanType.NULL_VALUE) == 0xff  # typemax(UInt8)
        
        # Test SBE interface functions
        @test isdefined(test_module, :sbe_encode_value)
        @test isdefined(test_module, :sbe_decode_value)
        @test isdefined(test_module, :encoding_type)
        @test isdefined(test_module, :null_value)
        
        sbe_encode_value = getfield(test_module, :sbe_encode_value)
        sbe_decode_value = getfield(test_module, :sbe_decode_value)
        encoding_type = getfield(test_module, :encoding_type)
        null_value = getfield(test_module, :null_value)
        
        # Test encoding functions
        @test sbe_encode_value(BooleanType.F) == UInt8(0)
        @test sbe_encode_value(BooleanType.T) == UInt8(1)
        @test sbe_encode_value(BooleanType.NULL_VALUE) == UInt8(0xff)
        
        # Test decoding functions
        @test sbe_decode_value(BooleanType, UInt8(0)) == BooleanType.F
        @test sbe_decode_value(BooleanType, UInt8(1)) == BooleanType.T
        @test sbe_decode_value(BooleanType, UInt8(0xff)) == BooleanType.NULL_VALUE
        @test sbe_decode_value(BooleanType, UInt8(99)) == BooleanType.NULL_VALUE  # Unknown value
        
        # Test metadata functions
        @test encoding_type(BooleanType) == UInt8
        @test encoding_type(BooleanType.F) == UInt8
        @test null_value(BooleanType) == BooleanType.NULL_VALUE
        @test null_value(BooleanType.F) == BooleanType.NULL_VALUE
    end
    
    @testset "Model Enum Generation (char encoding)" begin
        # Create a test Model enum definition (from example schema) 
        model_enum = Schema.EnumType(
            "Model",
            "char",
            [
                Schema.ValidValue("A", "A", "", 0, nothing),
                Schema.ValidValue("B", "B", "", 0, nothing),
                Schema.ValidValue("C", "C", "", 0, nothing)
            ],
            nothing, nothing, "", 0, nothing
        )
        
        schema = Schema.MessageSchema(
            UInt16(1), UInt16(0), "5.2", "test", "littleEndian", "messageHeader",
            "Test schema for enum types",
            [model_enum],
            Schema.MessageDefinition[]
        )
        
        # Create a test module for generating the enum type
        test_module_name = Symbol("TestModelEnumModule")
        Core.eval(Main, :(module $test_module_name end))
        test_module = getfield(Main, test_module_name)
        
        # Import EnumX into the test module
        Core.eval(test_module, :(using EnumX))
        
        # Generate the enum type
        result = SBE.generate_complete_enum_type!(test_module, model_enum, schema)
        
        @test result == :Model
        @test isdefined(test_module, :Model)
        
        # Get the generated enum type
        Model = getfield(test_module, :Model)
        
        # Test enum structure
        @test Model <: EnumX.Enum
        @test Model.A isa Model
        @test Model.B isa Model
        @test Model.C isa Model
        @test Model.NULL_VALUE isa Model
        
        # Test enum values (char encoding uses UInt8)
        @test UInt8(Model.A) == UInt8('A')  # 0x41
        @test UInt8(Model.B) == UInt8('B')  # 0x42
        @test UInt8(Model.C) == UInt8('C')  # 0x43
        @test UInt8(Model.NULL_VALUE) == 0xff  # typemax(UInt8)
        
        # Test SBE interface functions exist
        sbe_encode_value = getfield(test_module, :sbe_encode_value)
        sbe_decode_value = getfield(test_module, :sbe_decode_value)
        encoding_type = getfield(test_module, :encoding_type)
        
        # Test encoding functions
        @test sbe_encode_value(Model.A) == UInt8('A')
        @test sbe_encode_value(Model.B) == UInt8('B')
        @test sbe_encode_value(Model.C) == UInt8('C')
        
        # Test decoding functions
        @test sbe_decode_value(Model, UInt8('A')) == Model.A
        @test sbe_decode_value(Model, UInt8('B')) == Model.B
        @test sbe_decode_value(Model, UInt8('C')) == Model.C
        @test sbe_decode_value(Model, UInt8('X')) == Model.NULL_VALUE  # Unknown value
        
        # Test metadata functions
        @test encoding_type(Model) == UInt8
    end
    
    @testset "BoostType Enum Generation (nested in composite)" begin
        # Create a BoostType enum (from Booster composite in example schema)
        boost_enum = Schema.EnumType(
            "BoostType",
            "char",
            [
                Schema.ValidValue("TURBO", "T", "", 0, nothing),
                Schema.ValidValue("SUPERCHARGER", "S", "", 0, nothing),
                Schema.ValidValue("NITROUS", "N", "", 0, nothing),
                Schema.ValidValue("KERS", "K", "", 0, nothing)
            ],
            nothing, nothing, "", 0, nothing
        )
        
        schema = Schema.MessageSchema(
            UInt16(1), UInt16(0), "5.2", "test", "littleEndian", "messageHeader",
            "Test schema for enum types",
            [boost_enum],
            Schema.MessageDefinition[]
        )
        
        # Create a test module for generating the enum type
        test_module_name = Symbol("TestBoostEnumModule")
        Core.eval(Main, :(module $test_module_name end))
        test_module = getfield(Main, test_module_name)
        
        # Import EnumX into the test module
        Core.eval(test_module, :(using EnumX))
        
        # Generate the enum type
        result = SBE.generate_complete_enum_type!(test_module, boost_enum, schema)
        
        @test result == :BoostType
        @test isdefined(test_module, :BoostType)
        
        # Get the generated enum type
        BoostType = getfield(test_module, :BoostType)
        
        # Test enum structure
        @test BoostType <: EnumX.Enum
        @test BoostType.TURBO isa BoostType
        @test BoostType.SUPERCHARGER isa BoostType
        @test BoostType.NITROUS isa BoostType
        @test BoostType.KERS isa BoostType
        @test BoostType.NULL_VALUE isa BoostType
        
        # Test enum values
        @test UInt8(BoostType.TURBO) == UInt8('T')
        @test UInt8(BoostType.SUPERCHARGER) == UInt8('S') 
        @test UInt8(BoostType.NITROUS) == UInt8('N')
        @test UInt8(BoostType.KERS) == UInt8('K')
        @test UInt8(BoostType.NULL_VALUE) == 0xff
        
        # Test encoding/decoding
        sbe_encode_value = getfield(test_module, :sbe_encode_value)
        sbe_decode_value = getfield(test_module, :sbe_decode_value)
        
        @test sbe_encode_value(BoostType.TURBO) == UInt8('T')
        @test sbe_decode_value(BoostType, UInt8('S')) == BoostType.SUPERCHARGER
    end
    
    @testset "Enum Generation Error Handling" begin
        # Test enum with invalid values that need fallback
        problematic_enum = Schema.EnumType(
            "ProblematicEnum",
            "uint16",
            [
                Schema.ValidValue("VALID", "100", "", 0, nothing),
                Schema.ValidValue("INVALID", "not_a_number", "", 0, nothing)
            ],
            nothing, nothing, "", 0, nothing
        )
        
        schema = Schema.MessageSchema(
            UInt16(1), UInt16(0), "5.2", "test", "littleEndian", "messageHeader",
            "Test schema for enum types",
            [problematic_enum],
            Schema.MessageDefinition[]
        )
        
        # Create a test module
        test_module_name = Symbol("TestProblematicEnumModule")
        Core.eval(Main, :(module $test_module_name end))
        test_module = getfield(Main, test_module_name)
        
        # Import EnumX
        Core.eval(test_module, :(using EnumX))
        
        # Generate the enum type - should not error, should use fallbacks
        result = SBE.generate_complete_enum_type!(test_module, problematic_enum, schema)
        
        @test result == :ProblematicEnum
        @test isdefined(test_module, :ProblematicEnum)
        
        ProblematicEnum = getfield(test_module, :ProblematicEnum)
        
        # Test that valid value works
        @test UInt16(ProblematicEnum.VALID) == 100
        
        # Test that invalid value got fallback (0)
        @test UInt16(ProblematicEnum.INVALID) == 0
        
        # Test NULL_VALUE
        @test UInt16(ProblematicEnum.NULL_VALUE) == typemax(UInt16)
    end
end
