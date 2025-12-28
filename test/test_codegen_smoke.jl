using Test
using SBE

@testset "Codegen Smoke" begin
    schema_xml = """
    <sbe:messageSchema xmlns:sbe="http://fixprotocol.io/2016/sbe"
                       package="smoke"
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
        </types>
        <sbe:message name="Ping" id="1">
            <field name="value" id="1" type="uint32"/>
        </sbe:message>
    </sbe:messageSchema>
    """

    mktempdir() do dir
        schema_path = joinpath(dir, "smoke.xml")
        output_path = joinpath(dir, "Smoke.jl")
        write(schema_path, schema_xml)

        code_str = SBE.generate(schema_path)
        @test occursin("module Smoke", code_str)

        SBE.generate(schema_path, output_path)
        @test isfile(output_path)

        mod = Module(:SmokeModule)
        Base.include_string(mod, code_str)
        @test isdefined(mod, :Smoke)

        smoke = Base.invokelatest(getfield, mod, :Smoke)
        ping = Base.invokelatest(getfield, smoke, :Ping)
        encoder = Base.invokelatest(getfield, ping, :Encoder)
        decoder = Base.invokelatest(getfield, ping, :Decoder)
        wrap_and_apply_header! = Base.invokelatest(getfield, ping, :wrap_and_apply_header!)
        wrap! = Base.invokelatest(getfield, ping, :wrap!)
        header_mod = Base.invokelatest(getfield, smoke, :MessageHeader)
        header_encoder = Base.invokelatest(getfield, header_mod, :Encoder)
        value! = Base.invokelatest(getfield, ping, :value!)
        value = Base.invokelatest(getfield, ping, :value)

        buffer = zeros(UInt8, 64)
        header = Base.invokelatest(header_encoder, buffer, 0)
        enc = Base.invokelatest(encoder, typeof(buffer))
        Base.invokelatest(wrap_and_apply_header!, enc, buffer, 0; header=header)
        Base.invokelatest(value!, enc, UInt32(99))
        dec = Base.invokelatest(decoder, typeof(buffer))
        Base.invokelatest(wrap!, dec, buffer, 0)
        @test Base.invokelatest(value, dec) == UInt32(99)
    end
end
