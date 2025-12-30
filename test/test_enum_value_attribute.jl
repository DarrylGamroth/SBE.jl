using Test
using SBE

@testset "Enum value attribute" begin
    xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe"
                       package="example"
                       id="1"
                       version="0"
                       semanticVersion="1.0"
                       byteOrder="littleEndian">
        <types>
            <composite name="messageHeader">
                <type name="blockLength" primitiveType="uint16"/>
                <type name="templateId" primitiveType="uint16"/>
                <type name="schemaId" primitiveType="uint16"/>
                <type name="version" primitiveType="uint16"/>
            </composite>
            <enum name="Bool" encodingType="uint8">
                <validValue name="FALSE" value="0"/>
                <validValue name="TRUE" value="1"/>
            </enum>
        </types>
        <message name="Dummy" id="1" blockLength="0">
        </message>
    </sbe:messageSchema>
    """

    schema = SBE.parse_xml_schema(xml)
    enum_type = schema.types_by_name["Bool"]
    @test length(enum_type.valid_values) == 2
    @test enum_type.valid_values[1].primitive_value.value == "0"
    @test enum_type.valid_values[2].primitive_value.value == "1"
end
