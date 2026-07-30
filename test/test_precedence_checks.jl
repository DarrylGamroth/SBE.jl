using Test
using SBE
using AllocCheck

function caught_precedence_error(f)
    try
        f()
        return nothing
    catch error
        return error
    end
end

function encode_checked_multiple!(encoder, buffer)
    Checked = OrderCheckChecked.MultipleVarLength
    Checked.wrap_and_apply_header!(encoder, buffer, 0)
    Checked.a!(encoder, 42)
    Checked.b!(encoder, "abc")
    Checked.c!(encoder, "def")
    SBE.check_encoding_is_complete(encoder)
    return nothing
end

function decode_checked_multiple!(decoder, buffer)
    Checked = OrderCheckChecked.MultipleVarLength
    Checked.wrap!(decoder, buffer, 0)
    Checked.a(decoder)
    Checked.b(decoder)
    Checked.c(decoder)
    return nothing
end

@testset "Generated precedence checks" begin
    @testset "Generation-time specialization" begin
        schema_path = joinpath(
            @__DIR__,
            "resources",
            "basic-variable-length-schema.xml",
        )
        unchecked = SBE.generate(
            schema_path;
            module_name=:UncheckedSource,
            suppress_warnings=true,
        )
        checked = SBE.generate(
            schema_path;
            module_name=:CheckedSource,
            suppress_warnings=true,
            precedence_checks=true,
        )

        @test !occursin("codec_state", unchecked)
        @test !occursin("_encoder_precedence_", unchecked)
        @test !occursin("check_encoding_is_complete", unchecked)
        @test occursin("codec_state", checked)
        @test occursin("_encoder_precedence_", checked)
        @test occursin("check_encoding_is_complete", checked)

        ir = SBE.generate_ir(
            SBE.parse_xml_schema_file(
                schema_path;
                suppress_warnings=true,
            ),
        )
        checked_from_ir = SBE.generate_from_ir(
            ir;
            module_name=:CheckedIrSource,
            precedence_checks=true,
        )
        @test occursin("codec_state", checked_from_ir)

        mktempdir() do dir
            output_path = joinpath(dir, "CheckedIrSource.jl")
            @test SBE.generate_from_ir(
                ir,
                output_path;
                module_name=:CheckedIrSource,
                precedence_checks=true,
            ) == output_path
            @test occursin("codec_state", read(output_path, String))
        end
    end

    @testset "Unchecked and checked wire parity" begin
        Unchecked = OrderCheck.MultipleVarLength
        Checked = OrderCheckChecked.MultipleVarLength
        unchecked_buffer = zeros(UInt8, 128)
        checked_buffer = zeros(UInt8, 128)

        unchecked_encoder = Unchecked.Encoder(unchecked_buffer)
        Unchecked.a!(unchecked_encoder, 42)
        Unchecked.b!(unchecked_encoder, "abc")
        Unchecked.c!(unchecked_encoder, "def")

        checked_encoder = Checked.Encoder(checked_buffer)
        Checked.a!(checked_encoder, 42)
        Checked.b!(checked_encoder, "abc")
        Checked.c!(checked_encoder, "def")
        SBE.check_encoding_is_complete(checked_encoder)

        unchecked_length = SBE.sbe_frame_length(unchecked_encoder)
        checked_length = SBE.sbe_frame_length(checked_encoder)
        @test checked_length == unchecked_length
        @test checked_buffer[1:checked_length] ==
              unchecked_buffer[1:unchecked_length]

        checked_decoder = Checked.Decoder(unchecked_buffer)
        @test Checked.a(checked_decoder) == 42
        @test Checked.b(checked_decoder) == "abc"
        @test Checked.c(checked_decoder) == "def"

        unchecked_decoder = Unchecked.Decoder(checked_buffer)
        @test Unchecked.a(unchecked_decoder) == 42
        @test Unchecked.b(unchecked_decoder) == "abc"
        @test Unchecked.c(unchecked_decoder) == "def"
    end

    @testset "Variable data must follow schema order" begin
        Codec = OrderCheckChecked.MultipleVarLength
        buffer = zeros(UInt8, 128)

        encoder = Codec.Encoder(buffer)
        error = caught_precedence_error(() -> Codec.c!(encoder, "def"))
        @test error isa SBE.PrecedenceError
        message = sprint(showerror, error)
        @test occursin("cannot access field \"c\"", message)
        @test occursin("state V0_BLOCK", message)
        @test occursin("b(?)", message)
        @test occursin("MultipleVarLength.Encoder", message)

        Codec.wrap_and_apply_header!(encoder, buffer)
        Codec.b!(encoder, "abc")
        Codec.c!(encoder, "def")
        @test_throws SBE.PrecedenceError Codec.b!(encoder, "again")

        decoder = Codec.Decoder(buffer)
        @test Codec.b_length(decoder) == 3
        @test Codec.b_length(decoder) == 3
        @test Codec.skip_b!(decoder) == 3
        @test Codec.c(decoder) == "def"
        @test_throws SBE.PrecedenceError Codec.b(decoder)
    end

    @testset "Top-level fixed fields remain random access" begin
        Codec = OrderCheckChecked.MultipleVarLength
        buffer = zeros(UInt8, 128)
        encoder = Codec.Encoder(typeof(buffer))

        @test_throws SBE.PrecedenceError Codec.a!(encoder, 1)
        Codec.wrap_and_apply_header!(encoder, buffer)
        Codec.b!(encoder, "abc")
        Codec.c!(encoder, "def")
        Codec.a!(encoder, 42)
        @test Codec.a(Codec.Decoder(buffer)) == 42
    end

    @testset "Group element access requires next!" begin
        Codec = OrderCheckChecked.GroupAndVarLength
        buffer = zeros(UInt8, 128)
        encoder = Codec.Encoder(buffer)
        group = Codec.b!(encoder, 1)

        @test_throws SBE.PrecedenceError Codec.B.c!(group, 7)
        Codec.B.next!(group)
        Codec.B.c!(group, 7)
        Codec.d!(encoder, "done")
        SBE.check_encoding_is_complete(encoder)

        decoder = Codec.Decoder(buffer)
        decoded_group = Codec.b(decoder)
        @test_throws SBE.PrecedenceError Codec.B.c(decoded_group)
        Codec.B.next!(decoded_group)
        @test Codec.B.c(decoded_group) == 7
        @test Codec.d(decoder) == "done"
        @test_throws ErrorException Codec.B.next!(decoded_group)
    end

    @testset "Every fixed group-field shape is checked" begin
        buffer = zeros(UInt8, 256)

        CompositeCodec = OrderCheckChecked.CompositeInsideGroup
        composite_encoder = CompositeCodec.Encoder(buffer)
        composite_group = CompositeCodec.b!(composite_encoder, 1)
        @test_throws SBE.PrecedenceError CompositeCodec.B.c(composite_group)

        EnumCodec = OrderCheckChecked.EnumInsideGroup
        enum_encoder = EnumCodec.Encoder(buffer)
        enum_group = EnumCodec.b!(enum_encoder, 1)
        @test_throws SBE.PrecedenceError EnumCodec.B.c!(
            enum_group,
            OrderCheckChecked.Direction.BUY,
        )

        ArrayCodec = OrderCheckChecked.ArrayInsideGroup
        array_encoder = ArrayCodec.Encoder(buffer)
        array_group = ArrayCodec.b!(array_encoder, 1)
        @test_throws SBE.PrecedenceError ArrayCodec.B.c!(
            array_group,
            UInt8[127, 0, 0, 1],
        )

        SetCodec = OrderCheckChecked.BitSetInsideGroup
        set_encoder = SetCodec.Encoder(buffer)
        set_group = SetCodec.b!(set_encoder, 1)
        @test_throws SBE.PrecedenceError SetCodec.B.c(set_group)
    end

    @testset "Incomplete and reset group counts" begin
        Codec = OrderCheckChecked.GroupAndVarLength
        buffer = zeros(UInt8, 128)
        encoder = Codec.Encoder(buffer)

        group = Codec.b!(encoder, 2)
        Codec.B.next!(group)
        Codec.B.c!(group, 7)
        @test_throws SBE.PrecedenceError Codec.d!(encoder, "too early")
        @test_throws SBE.PrecedenceError SBE.check_encoding_is_complete(encoder)

        @test Codec.B.reset_count_to_index!(group) == 1
        Codec.d!(encoder, "done")
        SBE.check_encoding_is_complete(encoder)

        missing = Codec.Encoder(buffer)
        @test_throws SBE.PrecedenceError SBE.check_encoding_is_complete(missing)

        reset_before_next = Codec.Encoder(buffer)
        empty_after_reset = Codec.b!(reset_before_next, 2)
        @test Codec.B.reset_count_to_index!(empty_after_reset) == 0
        Codec.d!(reset_before_next, "")
        SBE.check_encoding_is_complete(reset_before_next)
    end

    @testset "Nested groups share one state machine" begin
        Codec = OrderCheckChecked.NestedGroups
        buffer = zeros(UInt8, 256)
        encoder = Codec.Encoder(buffer)

        outer = Codec.b!(encoder, 1)
        Codec.B.next!(outer)
        Codec.B.c!(outer, 1)
        @test_throws SBE.PrecedenceError Codec.B.f!(outer, 0)

        inner_d = Codec.B.d!(outer, 1)
        Codec.B.D.next!(inner_d)
        Codec.B.D.e!(inner_d, 2)
        Codec.B.f!(outer, 0)
        Codec.h!(encoder, 0)
        SBE.check_encoding_is_complete(encoder)

        decoder = Codec.Decoder(buffer)
        decoded_outer = Codec.b(decoder)
        Codec.B.next!(decoded_outer)
        @test Codec.B.c(decoded_outer) == 1
        decoded_d = Codec.B.d(decoded_outer)
        Codec.B.D.next!(decoded_d)
        @test Codec.B.D.e(decoded_d) == 2
        @test length(Codec.B.f(decoded_outer)) == 0
        @test length(Codec.h(decoder)) == 0
    end

    @testset "Acting-version state selection" begin
        Codec = OrderCheckChecked.AddGroupBeforeVarDataV1
        buffer = zeros(UInt8, 64)

        encoder = Codec.Encoder(typeof(buffer))
        Codec.wrap!(encoder, buffer, 0)
        Codec.c!(encoder, 0)
        Codec.b!(encoder, "v1")
        SBE.check_encoding_is_complete(encoder)

        future_decoder = Codec.Decoder(typeof(buffer))
        Codec.wrap!(
            future_decoder,
            buffer,
            0,
            SBE.sbe_block_length(encoder),
            99,
        )
        @test length(Codec.c(future_decoder)) == 0
        @test Codec.b(future_decoder) == "v1"

        old_buffer = zeros(UInt8, 64)
        old_buffer[5] = 0
        old_decoder = Codec.Decoder(typeof(old_buffer))
        Codec.wrap!(old_decoder, old_buffer, 0, 4, 0)
        @test length(Codec.c(old_decoder)) == 0
        @test Codec.b(old_decoder) == ""
    end

    @testset "Decoder rewind resets the checked traversal" begin
        Codec = OrderCheckChecked.MultipleVarLength
        buffer = zeros(UInt8, 128)
        encoder = Codec.Encoder(buffer)
        Codec.b!(encoder, "abc")
        Codec.c!(encoder, "def")

        decoder = Codec.Decoder(buffer)
        @test Codec.b(decoder) == "abc"
        @test Codec.c(decoder) == "def"
        SBE.sbe_rewind!(decoder)
        @test Codec.b(decoder) == "abc"
        @test Codec.c(decoder) == "def"
    end

    @testset "Terminal external variable data completes encoding" begin
        Codec = OrderCheckChecked.MultipleVarLength
        prefix = zeros(UInt8, 64)
        payload = UInt8[0xde, 0xad, 0xbe, 0xef]
        encoder = Codec.Encoder(prefix)
        Codec.b!(encoder, "abc")
        frame = Codec.c_external!(encoder, payload)

        SBE.check_encoding_is_complete(encoder)
        @test_throws SBE.PrecedenceError Codec.c!(encoder, "again")

        decoder = Codec.Decoder(frame)
        @test Codec.b(decoder) == "abc"
        @test Codec.c_bytes(decoder) === payload
    end

    @testset "Successful checked hot paths allocate zero bytes" begin
        Codec = OrderCheckChecked.MultipleVarLength
        buffer = zeros(UInt8, 128)
        encoder = Codec.Encoder(typeof(buffer))
        decoder = Codec.Decoder(typeof(buffer))

        encode_checked_multiple!(encoder, buffer)
        decode_checked_multiple!(decoder, buffer)

        @test (@allocated encode_checked_multiple!(encoder, buffer)) == 0
        @test (@allocated decode_checked_multiple!(decoder, buffer)) == 0
        @test isempty(check_allocs(
            encode_checked_multiple!,
            (typeof(encoder), typeof(buffer)),
        ))
        @test isempty(check_allocs(
            decode_checked_multiple!,
            (typeof(decoder), typeof(buffer)),
        ))
    end
end
