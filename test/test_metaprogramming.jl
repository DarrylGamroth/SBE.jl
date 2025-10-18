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
        # Parse real schema to test utility functions and type parsing
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
        
        # Test that we can find and analyze field types from real schema
        analyzed_fields = []
        
        for field in car_message.fields
            # Test that we can find the type definition for each field
            type_def = SBE.find_type_by_name(schema, field.type_ref)
            if type_def !== nothing && type_def isa Schema.EncodedType
                field_info = (
                    name = field.name,
                    type_name = SBE.to_pascal_case(field.name),
                    id = field.id,
                    offset = field.offset,
                    julia_type = SBE.to_julia_type(type_def.primitive_type),
                    length = type_def.length,
                    encoding_length = sizeof(SBE.to_julia_type(type_def.primitive_type)) * type_def.length
                )
                push!(analyzed_fields, field_info)
            end
        end
        
        @test length(analyzed_fields) > 0
        
        # Test specific field analysis
        some_numbers_field = findfirst(f -> f.name == "someNumbers", analyzed_fields)
        if some_numbers_field !== nothing
            field = analyzed_fields[some_numbers_field]
            @test field.julia_type == UInt32
            @test field.length == 4
            @test field.encoding_length == 16  # 4 * sizeof(UInt32)
        end
        
        vehicle_code_field = findfirst(f -> f.name == "vehicleCode", analyzed_fields)
        if vehicle_code_field !== nothing
            field = analyzed_fields[vehicle_code_field]
            @test field.julia_type == UInt8
            @test field.length == 6
            @test field.encoding_length == 6
        end
    end

    @testset "Meta Attribute Functions" begin
        # Test meta attribute function with pre-generated schema
        # The Baseline module is loaded in runtests.jl
        
        # Meta attributes in the new API are accessed through metadata constants
        # For field presence, all fields are "required" by default in the schema
        # Individual metadata is accessed via the field-specific constants (functions)
        @test isdefined(Baseline.Car, :modelYear_id)
        @test isdefined(Baseline.Car, :modelYear_since_version)
        @test Baseline.Car.modelYear_id() isa UInt16
        @test Baseline.Car.modelYear_since_version() isa UInt16
        
        # Test meta_attribute utility function behavior with schema field definitions
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
        
        # Test that field definitions have the expected metadata structure
        # (This tests the parsing and structure, not the runtime meta_attribute function)
        for field in car_message.fields
            @test hasfield(typeof(field), :id)
            @test hasfield(typeof(field), :name)
            @test hasfield(typeof(field), :type_ref)
            @test hasfield(typeof(field), :offset)
            @test hasfield(typeof(field), :presence)
            
            # Test that field definition contains expected values
            @test field.id isa UInt16
            @test field.name isa String
            @test field.presence isa String
        end
    end
end
