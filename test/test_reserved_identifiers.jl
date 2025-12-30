using Test
using SBE

@testset "Reserved identifiers codegen" begin
    schema_xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe"
                       package="reserved"
                       id="1"
                       version="0"
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
        <message name="Dummy" id="1">
            <field name="flag" id="1" type="Bool"/>
        </message>
    </sbe:messageSchema>
    """

    mktempdir() do dir
        schema_path = joinpath(dir, "reserved.xml")
        write(schema_path, schema_xml)
        code_str = SBE.generate(schema_path)

        @test occursin("@enumx T = SbeEnum Bool_::UInt8", code_str)
        @test occursin("using ..Bool_", code_str)
        @test !occursin(r"\\bBool::", code_str)
    end
end
