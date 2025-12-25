using Test
using SBE

const SBE_JAR_PATH = get(ENV, "SBE_JAR_PATH", joinpath(homedir(), ".cache", "sbe", "sbe-tool.jar"))

function token_signature(token::SBE.IR.Token)
    encoding = token.encoding
    return (
        token.signal,
        token.name,
        token.referenced_name,
        token.id,
        token.version,
        token.deprecated,
        token.encoded_length,
        token.offset,
        token.component_token_count,
        encoding.presence,
        encoding.primitive_type,
        encoding.byte_order,
        encoding.min_value === nothing ? nothing : encoding.min_value.value,
        encoding.max_value === nothing ? nothing : encoding.max_value.value,
        encoding.null_value === nothing ? nothing : encoding.null_value.value,
        encoding.const_value === nothing ? nothing : encoding.const_value.value,
        encoding.character_encoding,
        encoding.epoch,
        encoding.time_unit,
        encoding.semantic_type
    )
end

token_signatures(tokens::Vector{SBE.IR.Token}) = map(token_signature, tokens)

function compare_ir_tokens!(actual::SBE.IR.Ir, expected::SBE.IR.Ir)
    @test actual.id == expected.id
    @test actual.version == expected.version
    @test actual.package_name == expected.package_name
    @test actual.namespace_name == expected.namespace_name
    @test actual.byte_order == expected.byte_order

    @test token_signatures(actual.header_structure.tokens) ==
        token_signatures(expected.header_structure.tokens)

    @test sort(collect(keys(actual.messages_by_id))) == sort(collect(keys(expected.messages_by_id)))
    for (message_id, tokens) in expected.messages_by_id
        @test token_signatures(actual.messages_by_id[message_id]) == token_signatures(tokens)
    end

    @test sort(collect(keys(actual.types_by_name))) == sort(collect(keys(expected.types_by_name)))
    for (type_name, tokens) in expected.types_by_name
        @test token_signatures(actual.types_by_name[type_name]) == token_signatures(tokens)
    end
end

@testset "SBE IR Dogfooding" begin
    java = Sys.which("java")
    if java === nothing || !isfile(SBE_JAR_PATH)
        reason = "Skipping SBE IR dogfooding: missing java=$(java === nothing ? "not found" : java), " *
                 "SBE_JAR_PATH=$(isfile(SBE_JAR_PATH) ? "found" : "missing")"
        @test_skip reason
        return
    end

    schema_path = joinpath(@__DIR__, "resources", "example-schema.xml")
    schema_name = splitext(basename(schema_path))[1]

    mktempdir() do dir
        run(`$java -Dsbe.generate.stubs=false -Dsbe.generate.ir=true -Dsbe.output.dir=$dir -jar $SBE_JAR_PATH $schema_path`)
        ir_path = joinpath(dir, schema_name * ".sbeir")
        @test isfile(ir_path)

        xml_schema = SBE.parse_xml_schema(read(schema_path, String))
        xml_ir = SBE.generate_ir(xml_schema)

        ir_manual = SBE.decode_ir(ir_path)
        ir_generated = SBE.decode_ir_generated(ir_path)

        compare_ir_tokens!(ir_manual, xml_ir)
        compare_ir_tokens!(ir_generated, xml_ir)
        compare_ir_tokens!(ir_generated, ir_manual)
    end
end
