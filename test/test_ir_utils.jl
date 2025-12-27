using Test
using SBE

const IR = SBE.IR

function make_token(signal::IR.Signal.T; name="tok", encoded_length=0, offset=0, count=1,
    primitive_type=IR.PrimitiveType.NONE, presence=IR.Presence.REQUIRED)
    encoding = IR.Encoding(
        presence,
        primitive_type,
        :littleEndian,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing
    )
    return IR.Token(signal, name, nothing, "", nothing, -1, 0, 0, encoded_length, offset, count, encoding)
end

@testset "IR Utilities" begin
    @testset "IR API accessors" begin
        schema_path = joinpath(@__DIR__, "example-schema.xml")
        xml_content = read(schema_path, String)

        schema = SBE.parse_xml_schema(xml_content)
        ir = SBE.generate_ir(schema)
        ir_xml = SBE.generate_ir_xml(xml_content)
        ir_file = SBE.generate_ir_file(schema_path)

        @test SBE.IR.ir_package_name(ir) == "baseline"
        @test SBE.IR.ir_id(ir) == 1
        @test SBE.IR.ir_version(ir) == 0
        @test SBE.IR.ir_byte_order(ir) == :littleEndian

        @test !isempty(SBE.IR.ir_messages(ir))
        @test SBE.IR.ir_message(ir, 1) !== nothing
        @test !isempty(SBE.IR.ir_types(ir))

        @test SBE.IR.ir_id(ir_xml) == SBE.IR.ir_id(ir)
        @test SBE.IR.ir_id(ir_file) == SBE.IR.ir_id(ir)
    end

    @testset "PrimitiveValue helpers" begin
        long = IR.primitive_value_long(42, 2)
        @test long.representation == IR.PrimitiveValueRepresentation.LONG
        @test long.value == "42"
        @test long.size == 2

        dbl = IR.primitive_value_double(1.5, 4)
        @test dbl.representation == IR.PrimitiveValueRepresentation.DOUBLE
        @test dbl.value == "1.5"
        @test dbl.size == 4

        bytes = IR.primitive_value_bytes("ABC", "US-ASCII", 3)
        @test bytes.representation == IR.PrimitiveValueRepresentation.BYTE_ARRAY
        @test bytes.value == "ABC"
        @test bytes.character_encoding == "US-ASCII"
        @test bytes.size == 3
    end

    @testset "Array length" begin
        tok = make_token(IR.Signal.ENCODING; encoded_length=4, primitive_type=IR.PrimitiveType.UINT16)
        @test IR.array_length(tok) == 2
    end

    @testset "Token collectors" begin
        tokens = IR.Token[
            make_token(IR.Signal.BEGIN_FIELD; name="a", count=1),
            make_token(IR.Signal.BEGIN_FIELD; name="b", count=1),
            make_token(IR.Signal.BEGIN_GROUP; name="g", count=1),
        ]
        fields = IR.Token[]
        next_index = IR.collect_fields(tokens, 1, fields)
        @test length(fields) == 2
        @test fields[1].name == "a"
        @test fields[2].name == "b"
        @test next_index == 3
    end

    @testset "Signal helpers" begin
        tokens = IR.Token[
            make_token(IR.Signal.BEGIN_GROUP; name="A", count=1),
            make_token(IR.Signal.BEGIN_GROUP; name="B", count=1),
            make_token(IR.Signal.END_GROUP; name="B", count=1),
            make_token(IR.Signal.END_GROUP; name="A", count=1),
            make_token(IR.Signal.BEGIN_GROUP; name="C", count=1),
            make_token(IR.Signal.END_GROUP; name="C", count=1),
        ]
        end_idx = IR.find_end_signal(tokens, 1, IR.Signal.END_GROUP, "A")
        @test end_idx == 4
        @test IR.find_sub_group_names(tokens) == ["A", "C"]
        @test IR.find_signal(tokens, IR.Signal.BEGIN_GROUP) == 1
        @test IR.find_signal(tokens, IR.Signal.END_ENUM) == -1
    end
end

@testset "Codegen Utilities" begin
    @testset "extract_expr_from_quote" begin
        quoted = quote
            a = 1
            b = 2
        end
        expr = SBE.extract_expr_from_quote(quoted, :(=))
        @test expr isa Expr
        @test expr.head == :(=)
        @test expr.args[1] == :a

        any_expr = SBE.extract_expr_from_quote(quoted)
        @test any_expr isa Expr

        @test_throws ErrorException SBE.extract_expr_from_quote(quote end, :(=))
    end

    @testset "AbstractSbeGroup iterate" begin
        mutable struct TestGroup <: SBE.AbstractSbeGroup
            position_ptr::SBE.PositionPointer
            count::Int
            index::Int
            offset::Int
        end

        SBE.sbe_acting_block_length(::TestGroup) = 4

        group = TestGroup(SBE.PositionPointer(10), 2, 0, 0)
        @test length(group) == 2

        item, _ = iterate(group)
        @test item.offset == 10
        @test item.index == 1
        @test SBE.sbe_position(group) == 14

        item, _ = iterate(group)
        @test item.offset == 14
        @test item.index == 2
        @test SBE.sbe_position(group) == 18

        @test iterate(group) === nothing
    end
end
