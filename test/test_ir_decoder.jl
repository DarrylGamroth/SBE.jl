using Test
using SBE

const SBE_VERSION = selected_sbetool_version()
const SBE_JAR_PATH = get(
    ENV,
    "SBE_JAR_PATH",
    joinpath(homedir(), ".cache", "sbe", "sbe-all-$(SBE_VERSION).jar")
)

const TEST_SBE_IR_CODEC_NAME = SBE.@load_schema(
    "../src/resources/sbe-ir.xml";
    module_name=:TestSbeIrCodec
)

empty_string_to_nothing(value::String) = isempty(value) ? nothing : value

function generated_sbe_ir_summary(buffer::AbstractVector{UInt8})
    mod = TestSbeIrCodec
    position = SBE.PositionPointer()
    frame = mod.FrameCodec.Decoder(typeof(buffer))
    frame.position_ptr = position
    mod.FrameCodec.wrap!(
        frame,
        buffer,
        0,
        mod.FrameCodec.sbe_block_length(mod.FrameCodec.Decoder),
        mod.FrameCodec.sbe_schema_version(mod.FrameCodec.Decoder)
    )
    frame_summary = (
        id=mod.FrameCodec.irId(frame),
        ir_version=mod.FrameCodec.irVersion(frame),
        schema_version=mod.FrameCodec.schemaVersion(frame),
        package_name=String(mod.FrameCodec.packageName(frame)),
        namespace_name=empty_string_to_nothing(String(mod.FrameCodec.namespaceName(frame))),
        semantic_version=empty_string_to_nothing(String(mod.FrameCodec.semanticVersion(frame)))
    )

    token_summaries = NamedTuple[]
    token_block_length = mod.TokenCodec.sbe_block_length(mod.TokenCodec.Decoder)
    token_schema_version = mod.TokenCodec.sbe_schema_version(mod.TokenCodec.Decoder)
    offset = position[]
    while offset < length(buffer)
        token_position = SBE.PositionPointer(offset)
        token = mod.TokenCodec.Decoder(typeof(buffer))
        token.position_ptr = token_position
        mod.TokenCodec.wrap!(
            token,
            buffer,
            offset,
            token_block_length,
            token_schema_version
        )

        scalars = (
            offset=mod.TokenCodec.tokenOffset(token),
            encoded_length=mod.TokenCodec.tokenSize(token),
            id=mod.TokenCodec.fieldId(token),
            version=mod.TokenCodec.tokenVersion(token),
            component_token_count=mod.TokenCodec.componentTokenCount(token),
            signal=SBE.IrDecoder.map_signal(UInt8(mod.TokenCodec.signal(token))),
            primitive_type=SBE.IrDecoder.map_primitive_type(UInt8(mod.TokenCodec.primitiveType(token))),
            byte_order=SBE.IrDecoder.map_byte_order(UInt8(mod.TokenCodec.byteOrder(token))),
            presence=SBE.IrDecoder.map_presence(UInt8(mod.TokenCodec.presence(token))),
            deprecated=mod.TokenCodec.deprecated(token)
        )
        name = String(mod.TokenCodec.name(token))
        mod.TokenCodec.constValue(token)
        mod.TokenCodec.minValue(token)
        mod.TokenCodec.maxValue(token)
        mod.TokenCodec.nullValue(token)
        character_encoding = empty_string_to_nothing(
            String(mod.TokenCodec.characterEncoding(token))
        )
        epoch = empty_string_to_nothing(String(mod.TokenCodec.epoch(token)))
        time_unit = empty_string_to_nothing(String(mod.TokenCodec.timeUnit(token)))
        semantic_type = empty_string_to_nothing(String(mod.TokenCodec.semanticType(token)))
        description = String(mod.TokenCodec.description(token))
        referenced_name = empty_string_to_nothing(String(mod.TokenCodec.referencedName(token)))
        package_name = empty_string_to_nothing(String(mod.TokenCodec.packageName(token)))

        push!(
            token_summaries,
            merge(
                scalars,
                (;
                    name,
                    character_encoding,
                    epoch,
                    time_unit,
                    semantic_type,
                    description,
                    referenced_name,
                    package_name
                )
            )
        )
        offset = token_position[]
    end
    return frame_summary, token_summaries, offset
end

function serialized_token_summary(token::SBE.IR.Token)
    return (
        offset=token.offset,
        encoded_length=token.encoded_length,
        id=token.id,
        version=token.version,
        component_token_count=token.component_token_count,
        signal=token.signal,
        primitive_type=token.encoding.primitive_type,
        byte_order=token.encoding.byte_order,
        presence=token.encoding.presence,
        deprecated=token.deprecated,
        name=token.name,
        character_encoding=token.encoding.character_encoding,
        epoch=token.encoding.epoch,
        time_unit=token.encoding.time_unit,
        semantic_type=token.encoding.semantic_type,
        description=token.description,
        referenced_name=token.referenced_name,
        package_name=token.package_name
    )
end

function serialized_ir_tokens(ir::SBE.IR.Ir)
    tokens = copy(ir.header_structure.tokens)
    for message_id in sort!(collect(keys(ir.messages_by_id)))
        append!(tokens, ir.messages_by_id[message_id])
    end
    return tokens
end

function normalize_primitive_value(
    primitive_type::SBE.IR.PrimitiveType.T,
    value::Union{Nothing, String}
)
    value === nothing && return nothing
    if primitive_type == SBE.IR.PrimitiveType.CHAR
        all(isdigit, value) && return value
        if ncodeunits(value) == 1
            return string(Int(codeunit(value, 1)))
        end
    end
    return value
end

function normalize_character_encoding(
    primitive_type::SBE.IR.PrimitiveType.T,
    value::Union{Nothing, String}
)
    if primitive_type == SBE.IR.PrimitiveType.CHAR && value === nothing
        return "US-ASCII"
    end
    return value
end

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
        normalize_primitive_value(
            encoding.primitive_type,
            encoding.min_value === nothing ? nothing : encoding.min_value.value
        ),
        normalize_primitive_value(
            encoding.primitive_type,
            encoding.max_value === nothing ? nothing : encoding.max_value.value
        ),
        normalize_primitive_value(
            encoding.primitive_type,
            encoding.null_value === nothing ? nothing : encoding.null_value.value
        ),
        normalize_primitive_value(
            encoding.primitive_type,
            encoding.const_value === nothing ? nothing : encoding.const_value.value
        ),
        normalize_character_encoding(encoding.primitive_type, encoding.character_encoding),
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

@testset "Generated SBE IR codec dogfooding" begin
    @test TEST_SBE_IR_CODEC_NAME == :TestSbeIrCodec
    ir_path = joinpath(@__DIR__, "resources", "ir-basic-schema.sbeir")
    buffer = read(ir_path)
    ir = SBE.decode_ir(buffer)
    frame, tokens, final_offset = generated_sbe_ir_summary(buffer)

    @test frame == (
        id=ir.id,
        ir_version=Int32(0),
        schema_version=ir.version,
        package_name=ir.package_name,
        namespace_name=ir.namespace_name,
        semantic_version=isempty(ir.semantic_version) ? nothing : ir.semantic_version
    )
    @test tokens == serialized_token_summary.(serialized_ir_tokens(ir))
    @test final_offset == length(buffer)
end

@testset "Java SBE IR parity" begin
    java = Sys.which("java")
    java_opts = ["--add-opens=java.base/jdk.internal.misc=ALL-UNNAMED"]
    if java === nothing || !isfile(SBE_JAR_PATH)
        reason = "Skipping SBE IR dogfooding: missing java=$(java === nothing ? "not found" : java), " *
                 "SBE_JAR_PATH=$(isfile(SBE_JAR_PATH) ? "found" : "missing")"
        @test_skip reason
        return
    end

    schema_path = joinpath(@__DIR__, "resources", "example-schema.xml")
    schema_name = splitext(basename(schema_path))[1]

    mktempdir() do dir
        run(`$java $(java_opts...) -Dsbe.generate.stubs=false -Dsbe.generate.ir=true -Dsbe.output.dir=$dir -jar $SBE_JAR_PATH $schema_path`)
        ir_path = joinpath(dir, schema_name * ".sbeir")
        @test isfile(ir_path)

        xml_schema = SBE.parse_xml_schema(read(schema_path, String))
        xml_ir = SBE.generate_ir(xml_schema)

        ir_manual = SBE.decode_ir(ir_path)
        compare_ir_tokens!(ir_manual, xml_ir)
    end
end
