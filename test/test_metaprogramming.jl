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
    
    @testset "Utility Functions" begin
        # Test utility functions
        @test SBE.to_pascal_case("some_field") == "SomeField"
        @test SBE.to_pascal_case("single") == "Single"
        @test SBE.to_pascal_case("multi_word_field") == "MultiWordField"
        
        # Test type mapping
        @test SBE.to_julia_type("char") == UInt8
        @test SBE.to_julia_type("int8") == Int8
        @test SBE.to_julia_type("uint16") == UInt16
        @test SBE.to_julia_type("int32") == Int32
        @test SBE.to_julia_type("uint64") == UInt64
        @test SBE.to_julia_type("float") == Float32
        @test SBE.to_julia_type("double") == Float64
        
        # Test value parsing
        @test SBE.parse_typed_value("42", UInt32) == UInt32(42)
        @test SBE.parse_typed_value("0xff", UInt8) == UInt8(255)
        @test SBE.parse_typed_value("3.14", Float32) == Float32(3.14)
        @test SBE.parse_typed_value("0xffffffff", UInt32) == UInt32(0xffffffff)
    end
    
    @testset "XML Integration" begin
        # Test XML parsing with real schema
        schema_path = joinpath(@__DIR__, "example-schema.xml")
        @test isfile(schema_path)
        
        # Parse the schema
        xml_content = read(schema_path, String)
        schema = parse_sbe_schema(xml_content)
        
        @test schema isa Schema.MessageSchema
        @test schema.id == UInt16(1)
        @test schema.version == UInt16(0)
        @test schema.package == "baseline"
        @test schema.byte_order == "littleEndian"
        
        # Check that types were parsed
        @test length(schema.types) > 0
        @test length(schema.messages) > 0
        
        # Find specific types we know should be there
        model_year_type = SBE.find_type_by_name(schema, "ModelYear")
        @test model_year_type !== nothing
        @test model_year_type isa Schema.EncodedType
        @test model_year_type.primitive_type == "uint16"
        
        vehicle_code_type = SBE.find_type_by_name(schema, "VehicleCode")
        @test vehicle_code_type !== nothing
        @test vehicle_code_type isa Schema.EncodedType
        @test vehicle_code_type.primitive_type == "char"
        @test vehicle_code_type.length == 6
        
        some_numbers_type = SBE.find_type_by_name(schema, "someNumbers")
        @test some_numbers_type !== nothing
        @test some_numbers_type isa Schema.EncodedType
        @test some_numbers_type.primitive_type == "uint32"
        @test some_numbers_type.length == 4
    end

    @testset "Field Type Generation with Real Schema" begin
        # Parse real schema
        schema_path = joinpath(@__DIR__, "example-schema.xml")
        xml_content = read(schema_path, String)
        schema = parse_sbe_schema(xml_content)
        
        # Find the Car message (should be in the schema)
        car_message = nothing
        for msg in schema.messages
            if msg.name == "Car"
                car_message = msg
                break
            end
        end
        
        @test car_message !== nothing
        @test car_message isa Schema.MessageDefinition
        
        # Create the Car message type in SBE module for testing (only if not already defined)
        if !isdefined(SBE, :Car)
            @eval SBE begin
                struct Car{T<:AbstractVector{UInt8}} <: AbstractSbeMessage
                    buffer::T
                    offset::Int
                end
            end
        end
        
        # Test generating field types from real schema
        generated_types = Symbol[]
        
        for field in car_message.fields
            # Skip fields that reference complex types for now
            type_def = SBE.find_type_by_name(schema, field.type_ref)
            if type_def !== nothing && type_def isa Schema.EncodedType
                field_type_name = Symbol(SBE.to_pascal_case(field.name))
                
                # Only generate if not already defined
                if !isdefined(SBE, field_type_name)
                    field_type = SBE.generate_encoded_field_type(field, "Car", schema)
                    push!(generated_types, field_type)
                else
                    push!(generated_types, field_type_name)
                end
                
                # Test that the type was created and has correct hierarchy
                field_type = getfield(SBE, field_type_name)
                @test field_type <: AbstractSbeEncodedType
                
                # Test basic attributes
                @test SBE.id(field_type) == field.id
                @test SBE.since_version(field_type) == UInt16(field.since_version)
                @test SBE.encoding_offset(field_type) == field.offset
            end
        end
        
        @test length(generated_types) > 0
        println("Generated field types: ", generated_types)
        
        # Test working with generated types from real schema
        if :SomeNumbers in generated_types
            # Test SomeNumbers type from real schema
            @test Base.eltype(SBE.SomeNumbers) == UInt32
            @test Base.length(SBE.SomeNumbers) == 4
            @test SBE.encoding_length(SBE.SomeNumbers) == 16  # 4 * sizeof(UInt32)
            
            # Test creating the field (don't test data yet, focus on type correctness)
            buffer = zeros(UInt8, 32)
            car_msg = SBE.Car(buffer, 0)
            some_numbers_field = SBE.SomeNumbers(car_msg)
            
            # Test that the field can be created and has proper structure
            @test typeof(some_numbers_field) <: SBE.AbstractSbeField
            
            # Test basic accessor functionality (reading from zero buffer should give zeros)
            values = SBE.value(some_numbers_field)
            @test length(values) == 4
            @test all(v -> v isa UInt32, values)  # All values should be UInt32
        end
        
        if :VehicleCode in generated_types
            # Test VehicleCode type from real schema
            @test Base.eltype(SBE.VehicleCode) == UInt8
            @test Base.length(SBE.VehicleCode) == 6
            @test SBE.encoding_length(SBE.VehicleCode) == 6
        end
    end

    @testset "Field Type Generation (Manual Schema)" begin
        # Create a simple schema for testing
        test_schema = Schema.MessageSchema(
            UInt16(1),      # id
            UInt16(0),      # version  
            "5.2",          # semantic_version
            "test",         # package
            "littleEndian", # byte_order
            "messageHeader", # header_type
            "Test schema",  # description
            [
                # Simple uint32 type
                Schema.EncodedType(
                    "uint32Type", "uint32", 1, nothing, "0", "4294967294", 
                    nothing, nothing, "required", nothing, "32-bit unsigned", 0, nothing
                ),
                # Array type
                Schema.EncodedType(
                    "uint32Array", "uint32", 4, "0xffffffff", "0", "4294967294",
                    nothing, nothing, "required", nothing, "Array of 4 uint32", 0, nothing
                )
            ],
            [
                Schema.MessageDefinition(
                    "TestMessage", UInt16(1), "8", "Test message", 0,
                    nothing, nothing,
                    [
                        Schema.FieldDefinition(
                            "simpleField", UInt16(1), "uint32Type", 0, "Simple field", 0,
                            "required", nothing, "unix", nothing, nothing, nothing
                        ),
                        Schema.FieldDefinition(
                            "arrayField", UInt16(2), "uint32Array", 4, "Array field", 0,
                            "required", nothing, "unix", nothing, nothing, nothing
                        )
                    ],
                    Schema.GroupDefinition[], Schema.VarDataDefinition[]
                )
            ]
        )
        
        # Create a mock message type for testing in the SBE module (only if not already defined)
        if !isdefined(SBE, :TestMessage)
            @eval SBE begin
                struct TestMessage{T<:AbstractVector{UInt8}} <: AbstractSbeMessage
                    buffer::T
                    offset::Int
                end
            end
        end
        
        # Test field type generation (only generate if not already defined)
        if !isdefined(SBE, :SimpleField)
            simple_field_type = SBE.generate_encoded_field_type(
                test_schema.messages[1].fields[1], "TestMessage", test_schema
            )
            @test simple_field_type == :SimpleField
        end
        
        @test SBE.SimpleField <: AbstractSbeEncodedType
        
        # Test type-level functions
        @test SBE.id(SBE.SimpleField) == UInt16(1)
        @test SBE.since_version(SBE.SimpleField) == UInt16(0)
        @test SBE.encoding_offset(SBE.SimpleField) == 0
        @test SBE.encoding_length(SBE.SimpleField) == 4  # sizeof(UInt32)
        @test Base.length(SBE.SimpleField) == 1
        @test Base.eltype(SBE.SimpleField) == UInt32
        @test SBE.min_value(SBE.SimpleField) == UInt32(0)
        @test SBE.max_value(SBE.SimpleField) == UInt32(4294967294)
        
        # Test array field type generation (only generate if not already defined)
        if !isdefined(SBE, :ArrayField)
            array_field_type = SBE.generate_encoded_field_type(
                test_schema.messages[1].fields[2], "TestMessage", test_schema
            )
            @test array_field_type == :ArrayField
        end
        
        @test SBE.ArrayField <: AbstractSbeEncodedType
        
        # Test array type attributes
        @test SBE.id(SBE.ArrayField) == UInt16(2)
        @test SBE.encoding_offset(SBE.ArrayField) == 4
        @test SBE.encoding_length(SBE.ArrayField) == 16  # sizeof(UInt32) * 4
        @test Base.length(SBE.ArrayField) == 4
        @test Base.eltype(SBE.ArrayField) == UInt32
        @test SBE.null_value(SBE.ArrayField) == UInt32(0xffffffff)
    end
    
    @testset "Meta Attribute Functions" begin
        # Test meta_attribute function with manual schema
        # Using the TestMessage and fields created in the previous test
        
        # Create a test message instance
        buffer = zeros(UInt8, 32)
        test_msg = SBE.TestMessage(buffer, 0)
        
        # Test presence meta attribute (should return "required" for our test fields)
        presence_result = SBE.meta_attribute(test_msg, :presence)
        @test presence_result == Symbol("required")
        
        # Test unknown meta attribute (should return empty symbol)
        unknown_result = SBE.meta_attribute(test_msg, :unknown)
        @test unknown_result == Symbol("")
        
        # Test with real schema fields that have additional metadata
        schema_path = joinpath(@__DIR__, "example-schema.xml")
        @test isfile(schema_path)
        xml_content = read(schema_path, String)
        schema = parse_sbe_schema(xml_content)
        
        # Find the Car message
        car_message = nothing
        for msg in schema.messages
            if msg.name == "Car"
                car_message = msg
                break
            end
        end
        @test car_message !== nothing
        
        # Generate some field types from real schema (only if not already defined)
        modelYear_field = car_message.fields[2]  # modelYear field
        field_type_name = Symbol(SBE.to_pascal_case(modelYear_field.name))
        
        if !isdefined(SBE, field_type_name)
            generated_type = SBE.generate_encoded_field_type(modelYear_field, "Car", schema)
            @test generated_type == :ModelYear
        else
            @test field_type_name == :ModelYear
        end
        
        # Create a Car message instance
        car_buffer = zeros(UInt8, 64)
        car = SBE.Car(car_buffer, 0)
        
        # Test meta_attribute on real schema field
        presence_result = SBE.meta_attribute(car, :presence)
        @test presence_result == Symbol("required")
        
        # Test epoch (modelYear has epoch="unix" in the field definition)
        epoch_result = SBE.meta_attribute(car, :epoch)
        @test epoch_result == Symbol("unix")
        
        # Test time_unit (should be empty for modelYear)
        time_unit_result = SBE.meta_attribute(car, :time_unit)
        @test time_unit_result == Symbol("")  # modelYear doesn't have time_unit
        
        # Test semantic_type (should be empty for modelYear)
        semantic_type_result = SBE.meta_attribute(car, :semantic_type)
        @test semantic_type_result == Symbol("")  # modelYear doesn't have semantic_type
    end
    
    @testset "Field Value Accessors" begin
        # Create a test buffer with some data
        buffer = zeros(UInt8, 32)
        
        # Write some test data (little-endian UInt32 = 0x12345678)
        buffer[1:4] = [0x78, 0x56, 0x34, 0x12]  # Single value at offset 0
        
        # Write array data at offset 4
        for i in 0:3
            val = 0x11111111 * (i + 1)  # 0x11111111, 0x22222222, etc.
            bytes = reinterpret(UInt8, [htol(UInt32(val))])
            buffer[5+i*4:8+i*4] = bytes
        end
        
        test_msg = SBE.TestMessage(buffer, 0)
        
        # Test single field value access
        simple_field = SBE.SimpleField(test_msg)
        @test simple_field.buffer === buffer
        @test simple_field.offset == 0
        
        # Test reading value
        val = SBE.value(simple_field)
        @test val == 0x12345678
        
        # Test writing value
        SBE.value!(simple_field, UInt32(0x87654321))
        new_val = SBE.value(simple_field)
        @test new_val == 0x87654321
        
        # Test array field value access
        test_msg_array = SBE.TestMessage(buffer, 0)  # Array starts at offset 4
        array_field = SBE.ArrayField(test_msg_array)
        @test array_field.offset == 4
        
        # Test reading array
        arr = SBE.value(array_field)
        @test length(arr) == 4
        @test arr[1] == 0x11111111
        @test arr[2] == 0x22222222
        @test arr[3] == 0x33333333
        @test arr[4] == 0x44444444
        
        # Test writing to array
        new_arr = [0xAAAAAAAA, 0xBBBBBBBB, 0xCCCCCCCC, 0xDDDDDDDD]
        SBE.value!(array_field, new_arr)
        updated_arr = SBE.value(array_field)
        @test updated_arr[1] == 0xAAAAAAAA
        @test updated_arr[2] == 0xBBBBBBBB
        @test updated_arr[3] == 0xCCCCCCCC
        @test updated_arr[4] == 0xDDDDDDDD
    end
end
