using Test
using SBE

@testset "SbeTool schema compatibility regressions" begin
    resources = joinpath(@__DIR__, "resources")
    schemas = Dict{String, Any}()

    for (filename, expected_messages) in (
        ("FixBinary.xml", 29),
        ("ilinkbinary.xml", 48),
        ("issue835.xml", 1),
        ("code-generation-schema.xml", 3),
        ("dto-test-schema.xml", 3),
    )
        schema = SBE.parse_xml_schema(
            read(joinpath(resources, filename), String);
            suppress_warnings=true,
        )
        schemas[filename] = schema
        @test length(schema.messages) == expected_messages
    end

    fix_ir = SBE.generate_ir(schemas["FixBinary.xml"])
    constant_field = only(filter(fix_ir.messages_by_id[4]) do token
        token.signal == SBE.IR.Signal.BEGIN_FIELD && token.name == "MDUpdateAction"
    end)
    @test constant_field.encoding.presence == SBE.IR.Presence.CONSTANT

    character_ir = SBE.generate_ir_file(
        joinpath(resources, "new-order-single-schema.xml");
        suppress_warnings=true,
    )
    buy_value = only(filter(character_ir.types_by_name["sideEnum"]) do token
        token.signal == SBE.IR.Signal.VALID_VALUE && token.name == "Buy"
    end)
    @test buy_value.encoding.const_value.value == "49"

    big_endian_ir = SBE.generate_ir_file(
        joinpath(resources, "example-bigendian-test-schema.xml");
        suppress_warnings=true,
    )
    @test first(big_endian_ir.header_structure.tokens).encoding.byte_order == :littleEndian
    block_length = only(filter(big_endian_ir.header_structure.tokens) do token
        token.signal == SBE.IR.Signal.ENCODING && token.name == "blockLength"
    end)
    @test block_length.encoding.byte_order == :bigEndian

    group_ir = SBE.generate_ir_file(
        joinpath(resources, "basic-group-schema.xml");
        suppress_warnings=true,
    )
    num_in_group = only(filter(group_ir.types_by_name["groupSizeEncoding"]) do token
        token.signal == SBE.IR.Signal.ENCODING && token.name == "numInGroup"
    end)
    @test num_in_group.encoding.semantic_type === nothing

    included_schema = SBE.parse_xml_schema_file(
        joinpath(resources, "sub", "basic-schema.xml");
        suppress_warnings=true,
    )
    @test haskey(included_schema.types_by_name, "Symbol")
    @test only(included_schema.messages).id == 50001

    provenance = read(joinpath(resources, "UPSTREAM_SBETOOL.toml"), String)
    @test occursin("version = \"1.37.1\"", provenance)
    @test occursin("commit = \"2e78afe5addbc5f701e2d7f4528a8444bf25dd5b\"", provenance)
    @test occursin("fixture_count = 79", provenance)

    invalid_composite = read(
        joinpath(resources, "error-handler-invalid-composite.xml"),
        String,
    )
    expect_error(
        () -> SBE.parse_xml_schema(invalid_composite; suppress_warnings=true),
        "group not valid within composite",
    )

    invalid_group_count = read(joinpath(resources, "issue567-invalid.xml"), String)
    expect_error(
        () -> SBE.parse_xml_schema(invalid_group_count; suppress_warnings=true),
        "maxValue must be set for varData UINT32 type: max value allowed=2147483647",
    )
end
