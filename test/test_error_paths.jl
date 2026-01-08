using Test
using SBE

function expect_error(f::Function, needle::AbstractString)
    err = try
        f()
        nothing
    catch e
        e
    end
    @test err !== nothing
    @test occursin(needle, sprint(showerror, err))
end

@testset "Error Paths" begin
    expect_error(
        () -> SBE.parse_xml_schema("<badSchema/>"),
        "Expected root element 'messageSchema'"
    )

    enum_out_of_range = """
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe" id="1" version="0">
        <types>
            <enum name="BadEnum" encodingType="uint8" minValue="0" maxValue="1">
                <validValue name="TWO">2</validValue>
            </enum>
        </types>
    </sbe:messageSchema>
    """
    expect_error(
        () -> SBE.parse_xml_schema(enum_out_of_range),
        "enum value out of range"
    )

    enum_null_out_of_range = """
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe" id="1" version="0">
        <types>
            <enum name="BadEnum" encodingType="uint8" minValue="0" maxValue="1" nullValue="2"/>
        </types>
    </sbe:messageSchema>
    """
    expect_error(
        () -> SBE.parse_xml_schema(enum_null_out_of_range),
        "enum null value out of range"
    )

    enum_null_collision = """
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe" id="1" version="0">
        <types>
            <enum name="BadEnum" encodingType="uint8" presence="optional" nullValue="1">
                <validValue name="ONE">1</validValue>
            </enum>
        </types>
    </sbe:messageSchema>
    """
    expect_error(
        () -> SBE.parse_xml_schema(enum_null_collision),
        "enum null value collides with valid value"
    )

    enum_encoding_length = """
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe" id="1" version="0">
        <types>
            <type name="BadEnumEncoding" primitiveType="uint8" length="2"/>
            <enum name="BadEnum" encodingType="BadEnumEncoding">
                <validValue name="A">1</validValue>
            </enum>
        </types>
    </sbe:messageSchema>
    """
    expect_error(
        () -> SBE.parse_xml_schema(enum_encoding_length),
        "illegal encodingType for enum BadEnum length not equal to 1"
    )

    set_encoding_length = """
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe" id="1" version="0">
        <types>
            <type name="BadSetEncoding" primitiveType="uint8" length="2"/>
            <set name="BadSet" encodingType="BadSetEncoding">
                <choice name="A">0</choice>
            </set>
        </types>
    </sbe:messageSchema>
    """
    expect_error(
        () -> SBE.parse_xml_schema(set_encoding_length),
        "Illegal encodingType BadSetEncoding"
    )

    missing_ref_type = """
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe" id="1" version="0">
        <types>
            <composite name="Outer">
                <ref name="missing" type="Missing"/>
            </composite>
        </types>
    </sbe:messageSchema>
    """
    expect_error(
        () -> SBE.parse_xml_schema(missing_ref_type),
        "ref type not found: Missing"
    )

    circular_ref_type = """
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe" id="1" version="0">
        <types>
            <composite name="Loop">
                <ref name="self" type="Loop"/>
            </composite>
        </types>
    </sbe:messageSchema>
    """
    expect_error(
        () -> SBE.parse_xml_schema(circular_ref_type),
        "ref types cannot create circular dependencies: Loop"
    )

    invalid_group_dimension = """
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe" id="1" version="0">
        <types>
            <type name="notComposite" primitiveType="uint8"/>
        </types>
        <sbe:message name="BadGroup" id="1">
            <group name="G" id="1" dimensionType="notComposite">
                <field name="f" id="1" type="uint8"/>
            </group>
        </sbe:message>
    </sbe:messageSchema>
    """
    expect_error(
        () -> SBE.parse_xml_schema(invalid_group_dimension),
        "dimensionType must be a composite: notComposite"
    )

    invalid_data_type = """
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe" id="1" version="0">
        <types>
            <type name="notComposite" primitiveType="uint8"/>
        </types>
        <sbe:message name="BadData" id="1">
            <data name="D" id="1" type="notComposite"/>
        </sbe:message>
    </sbe:messageSchema>
    """
    expect_error(
        () -> SBE.parse_xml_schema(invalid_data_type),
        "data type is not composite: notComposite"
    )

    invalid_offset = """
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe" id="1" version="0">
        <sbe:message name="BadOffset" id="1">
            <field name="a" id="1" type="uint32" offset="0"/>
            <field name="b" id="2" type="uint8" offset="2"/>
        </sbe:message>
    </sbe:messageSchema>
    """
    expect_error(
        () -> SBE.parse_xml_schema(invalid_offset),
        "Offset provides insufficient space at field: b"
    )

    missing_field_type = """
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe" id="1" version="0">
        <sbe:message name="MissingType" id="1">
            <field name="a" id="1" type="Missing"/>
        </sbe:message>
    </sbe:messageSchema>
    """
    expect_error(
        () -> SBE.parse_xml_schema(missing_field_type),
        "could not find type: Missing"
    )

    invalid_value_ref = """
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe" id="1" version="0" headerType="hdr">
        <types>
            <composite name="hdr">
                <type name="blockLength" primitiveType="uint16"/>
                <type name="templateId" primitiveType="uint16"/>
                <type name="schemaId" primitiveType="uint16"/>
                <type name="version" primitiveType="uint16"/>
            </composite>
            <enum name="Side" encodingType="uint8">
                <validValue name="BUY">1</validValue>
            </enum>
            <type name="ConstType" primitiveType="uint8" presence="constant" valueRef="Side.SELL"/>
        </types>
        <sbe:message name="BadValueRef" id="1">
            <field name="side" id="1" type="ConstType"/>
        </sbe:message>
    </sbe:messageSchema>
    """
    expect_error(
        () -> SBE.generate_ir(SBE.parse_xml_schema(invalid_value_ref)),
        "valueRef for validValue name not found: SELL"
    )

    expect_error(
        () -> SBE.generate("does-not-exist.xml"),
        "Schema file not found: does-not-exist.xml"
    )
    expect_error(
        () -> SBE.generate("does-not-exist.xml", "out.jl"),
        "Schema file not found: does-not-exist.xml"
    )

    quoted = Expr(:block)
    expect_error(
        () -> SBE.extract_expr_from_quote(quoted),
        "Failed to extract expression from quote block"
    )
    expect_error(
        () -> SBE.extract_expr_from_quote(Expr(:block, :(x = 1)), :module),
        "Failed to extract :module expression from quote block"
    )

    struct DummyGroup <: SBE.AbstractSbeGroup
        count::Int
        index::Int
        position_ptr::SBE.PositionPointer
        offset::Int
    end
    SBE.sbe_acting_block_length(::DummyGroup) = 0

    g = DummyGroup(1, 1, SBE.PositionPointer(), 0)
    expect_error(
        () -> SBE.next!(g),
        "index >= count"
    )

    buffer = zeros(UInt8, 12)
    reinterpret(Int32, buffer)[1] = 0
    reinterpret(Int32, buffer)[2] = 1
    reinterpret(Int32, buffer)[3] = 0
    expect_error(
        () -> SBE.decode_ir(buffer),
        "Unknown IR version: 1"
    )
end
