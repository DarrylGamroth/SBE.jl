"""
Test IR (Intermediate Representation) Generation

Tests that schemas can be converted to IR format compatible with
the reference SBE implementation.
"""

using Test
using SBE

@testset "IR Generation" begin
    @testset "Basic Schema to IR" begin
        # Load a simple test schema
        xml_path = joinpath(@__DIR__, "example-schema.xml")
        xml_content = read(xml_path, String)
        schema = SBE.parse_sbe_schema(xml_content)
        
        # Convert to IR
        ir = SBE.schema_to_ir(schema)
        
        # Verify frame header
        @test ir.frame.ir_id == schema.id
        @test ir.frame.schema_version == schema.version
        @test ir.frame.package_name == schema.package
        @test ir.frame.semantic_version == schema.semantic_version
        
        # Verify tokens were generated
        @test length(ir.tokens) > 0
        
        # Check that we have message tokens
        message_tokens = filter(t -> t.signal == SBE.IR.BEGIN_MESSAGE, ir.tokens)
        @test length(message_tokens) == length(schema.messages)
        
        # Verify each message has corresponding tokens
        for message in schema.messages
            msg_token = findfirst(t -> t.signal == SBE.IR.BEGIN_MESSAGE && t.name == message.name, ir.tokens)
            @test msg_token !== nothing
            if msg_token !== nothing
                @test ir.tokens[msg_token].field_id == message.id
            end
        end
    end
    
    @testset "Type Tokens Generation" begin
        xml_path = joinpath(@__DIR__, "example-schema.xml")
        xml_content = read(xml_path, String)
        schema = SBE.parse_sbe_schema(xml_content)
        ir = SBE.schema_to_ir(schema)
        
        # Check for composite type tokens
        composite_begins = filter(t -> t.signal == SBE.IR.BEGIN_COMPOSITE, ir.tokens)
        composite_ends = filter(t -> t.signal == SBE.IR.END_COMPOSITE, ir.tokens)
        @test length(composite_begins) == length(composite_ends)
        
        # Check for enum type tokens
        enum_begins = filter(t -> t.signal == SBE.IR.BEGIN_ENUM, ir.tokens)
        enum_ends = filter(t -> t.signal == SBE.IR.END_ENUM, ir.tokens)
        @test length(enum_begins) == length(enum_ends)
        
        # Check for set type tokens
        set_begins = filter(t -> t.signal == SBE.IR.BEGIN_SET, ir.tokens)
        set_ends = filter(t -> t.signal == SBE.IR.END_SET, ir.tokens)
        @test length(set_begins) == length(set_ends)
    end
    
    @testset "Field Tokens" begin
        xml_path = joinpath(@__DIR__, "example-schema.xml")
        xml_content = read(xml_path, String)
        schema = SBE.parse_sbe_schema(xml_content)
        ir = SBE.schema_to_ir(schema)
        
        # Check that fields generate BEGIN_FIELD and END_FIELD tokens
        field_begins = filter(t -> t.signal == SBE.IR.BEGIN_FIELD, ir.tokens)
        field_ends = filter(t -> t.signal == SBE.IR.END_FIELD, ir.tokens)
        @test length(field_begins) == length(field_ends)
        @test length(field_begins) > 0  # Should have at least some fields
    end
    
    @testset "Group Tokens" begin
        xml_path = joinpath(@__DIR__, "example-schema.xml")
        xml_content = read(xml_path, String)
        schema = SBE.parse_sbe_schema(xml_content)
        ir = SBE.schema_to_ir(schema)
        
        # Check that groups generate BEGIN_GROUP and END_GROUP tokens
        group_begins = filter(t -> t.signal == SBE.IR.BEGIN_GROUP, ir.tokens)
        group_ends = filter(t -> t.signal == SBE.IR.END_GROUP, ir.tokens)
        @test length(group_begins) == length(group_ends)
    end
    
    @testset "Var Data Tokens" begin
        xml_path = joinpath(@__DIR__, "example-schema.xml")
        xml_content = read(xml_path, String)
        schema = SBE.parse_sbe_schema(xml_content)
        ir = SBE.schema_to_ir(schema)
        
        # Check that var data generates BEGIN_VAR_DATA and END_VAR_DATA tokens
        vardata_begins = filter(t -> t.signal == SBE.IR.BEGIN_VAR_DATA, ir.tokens)
        vardata_ends = filter(t -> t.signal == SBE.IR.END_VAR_DATA, ir.tokens)
        @test length(vardata_begins) == length(vardata_ends)
    end
    
    @testset "Token Structure Validation" begin
        xml_path = joinpath(@__DIR__, "example-schema.xml")
        xml_content = read(xml_path, String)
        schema = SBE.parse_sbe_schema(xml_content)
        ir = SBE.schema_to_ir(schema)
        
        # Verify that every BEGIN has a matching END
        signal_stack = SBE.IR.Signal[]
        for token in ir.tokens
            if token.signal in [SBE.IR.BEGIN_MESSAGE, SBE.IR.BEGIN_COMPOSITE, 
                               SBE.IR.BEGIN_FIELD, SBE.IR.BEGIN_GROUP,
                               SBE.IR.BEGIN_ENUM, SBE.IR.BEGIN_SET, SBE.IR.BEGIN_VAR_DATA]
                push!(signal_stack, token.signal)
            elseif token.signal in [SBE.IR.END_MESSAGE, SBE.IR.END_COMPOSITE,
                                   SBE.IR.END_FIELD, SBE.IR.END_GROUP,
                                   SBE.IR.END_ENUM, SBE.IR.END_SET, SBE.IR.END_VAR_DATA]
                # Pop matching BEGIN
                @test !isempty(signal_stack)
                if !isempty(signal_stack)
                    pop!(signal_stack)
                end
            end
        end
        
        # Stack should be empty at the end (all BEGINs matched with ENDs)
        @test isempty(signal_stack)
    end
    
    @testset "Primitive Type Mapping" begin
        # Test that primitive types are correctly mapped to IR enum values
        @test SBE.primitive_type_to_ir("char") == SBE.IR.PT_CHAR
        @test SBE.primitive_type_to_ir("int8") == SBE.IR.PT_INT8
        @test SBE.primitive_type_to_ir("int16") == SBE.IR.PT_INT16
        @test SBE.primitive_type_to_ir("int32") == SBE.IR.PT_INT32
        @test SBE.primitive_type_to_ir("int64") == SBE.IR.PT_INT64
        @test SBE.primitive_type_to_ir("uint8") == SBE.IR.PT_UINT8
        @test SBE.primitive_type_to_ir("uint16") == SBE.IR.PT_UINT16
        @test SBE.primitive_type_to_ir("uint32") == SBE.IR.PT_UINT32
        @test SBE.primitive_type_to_ir("uint64") == SBE.IR.PT_UINT64
        @test SBE.primitive_type_to_ir("float") == SBE.IR.PT_FLOAT
        @test SBE.primitive_type_to_ir("double") == SBE.IR.PT_DOUBLE
        @test SBE.primitive_type_to_ir("unknown") == SBE.IR.PT_NONE
    end
    
    @testset "Presence Mapping" begin
        # Test that presence values are correctly mapped to IR enum values
        @test SBE.presence_to_ir("required") == SBE.IR.SBE_REQUIRED
        @test SBE.presence_to_ir("optional") == SBE.IR.SBE_OPTIONAL
        @test SBE.presence_to_ir("constant") == SBE.IR.SBE_CONSTANT
        @test SBE.presence_to_ir("unknown") == SBE.IR.SBE_REQUIRED  # default
    end
end
