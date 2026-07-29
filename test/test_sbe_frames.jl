using Test
using SBE

@testset "Logical SBE Frames" begin
    @testset "Ordered regions" begin
        first = UInt8[0x01, 0x02]
        second = UInt8[0x03]
        third = UInt8[0x04, 0x05]
        frame = SBE.SbeFrame(first, second, third)

        @test collect(frame) == UInt8[0x01, 0x02, 0x03, 0x04, 0x05]
        @test SBE.sbe_wire_length(frame) == 5
        @test SBE.sbe_wire_length(first) == 2
        @test SBE.sbe_tail(frame) === third
        @test Tuple(SBE.sbe_regions(frame)) == (first, second, third)
        @test collect(view(frame, 2:4)) == UInt8[0x02, 0x03, 0x04]

        frame[4] = 0x44
        @test third[1] == 0x44

        accepts_vectored(
            ::AbstractVector{T}
        ) where {T <: AbstractVector{UInt8}} = true
        @test accepts_vectored(SBE.sbe_regions(frame))
    end

    @testset "Type-stable logical views" begin
        frame = SBE.SbeFrame(
            UInt8[0x01, 0x02],
            UInt8[0x03, 0x04]
        )
        prefix_view = view(frame, 1:2)
        crossing_view = view(frame, 2:3)
        tail_view = view(frame, 3:4)

        @test typeof(prefix_view) === typeof(crossing_view)
        @test typeof(crossing_view) === typeof(tail_view)
        @test collect(prefix_view) == UInt8[0x01, 0x02]
        @test collect(crossing_view) == UInt8[0x02, 0x03]
        @test collect(tail_view) == UInt8[0x03, 0x04]

        prefix_view[2] = 0x22
        crossing_view[2] = 0x33
        @test collect(frame) == UInt8[0x01, 0x22, 0x33, 0x04]
    end

    @testset "Scalar access across a region boundary" begin
        values = (
            Int16(-1234),
            Int32(-1234567),
            Int64(-123456789),
            UInt16(0xabcd),
            UInt32(0x01020304),
            UInt64(0x0102030405060708),
            Float32(1.25),
            Float64(-2.5)
        )

        for (encode, decode) in (
            (SBE.encode_value_le, SBE.decode_value_le),
            (SBE.encode_value_be, SBE.decode_value_be)
        ), value in values
            value_type = typeof(value)
            encoded = zeros(UInt8, sizeof(value_type))
            encode(value_type, encoded, 0, value)

            split = max(1, sizeof(value_type) ÷ 2)
            frame = SBE.SbeFrame(
                zeros(UInt8, split),
                zeros(UInt8, sizeof(value_type) - split)
            )
            encode(value_type, frame, 0, value)

            @test collect(frame) == encoded
            @test isequal(decode(value_type, frame, 0), value)
        end
    end

    @testset "Generated API surface" begin
        @test isdefined(Baseline.Car, :activationCode_external!)
        @test !isdefined(Baseline.Car, :manufacturer_external!)
        @test !isdefined(Baseline.Car, :model_external!)
        @test !isdefined(
            GroupWithData.TestMessage1.Entries,
            :varDataField_external!
        )

        external_doc =
            string(@doc Issue488Schema.Issue488.varData_external!)
        @test occursin("without copying", external_doc)
        @test occursin("final top-level variable-data field", external_doc)
    end

    @testset "External binary tail parity and decoding" begin
        payload = UInt8[0x01, 0x02, 0x03, 0x04]
        prefix = zeros(UInt8, 12)
        encoder = Issue488Schema.Issue488.Encoder(prefix)
        frame = Issue488Schema.Issue488.varData_external!(encoder, payload)

        @test SBE.sbe_frame_offset(encoder) == 0
        @test SBE.sbe_encoded_length(encoder) == 4 + length(payload)
        @test SBE.sbe_frame_length(encoder) == 12 + length(payload)
        @test SBE.sbe_wire_length(frame) == SBE.sbe_frame_length(encoder)
        @test SBE.sbe_regions(frame)[2] === payload

        contiguous = zeros(UInt8, length(frame))
        contiguous_encoder = Issue488Schema.Issue488.Encoder(contiguous)
        Issue488Schema.Issue488.varData!(contiguous_encoder, payload)
        @test collect(frame) == contiguous

        decoder = Issue488Schema.Issue488.Decoder(frame)
        decoded = Issue488Schema.Issue488.varData(decoder)
        @test collect(decoded) == payload
        @test parent(decoded) === payload
        payload[1] = 0x7f
        @test decoded[1] == 0x7f

        truncated = SBE.SbeFrame(prefix, payload[1:end-1])
        truncated_decoder = Issue488Schema.Issue488.Decoder(truncated)
        @test_throws ArgumentError begin
            Issue488Schema.Issue488.varData(truncated_decoder)
        end
    end

    @testset "External text and empty tails" begin
        text_prefix = zeros(UInt8, 9)
        text_encoder = BasicVariableLength.TestMessage1.Encoder(text_prefix)
        text_frame =
            BasicVariableLength.TestMessage1.encryptedNewPassword_external!(
                text_encoder,
                "secret"
            )
        text_decoder = BasicVariableLength.TestMessage1.Decoder(text_frame)
        @test BasicVariableLength.TestMessage1.encryptedNewPassword(
            text_decoder,
            String
        ) == "secret"

        empty_prefix = zeros(UInt8, 9)
        empty_encoder = BasicVariableLength.TestMessage1.Encoder(empty_prefix)
        empty_payload = UInt8[]
        empty_frame =
            BasicVariableLength.TestMessage1.encryptedNewPassword_external!(
                empty_encoder,
                empty_payload
            )
        empty_decoder = BasicVariableLength.TestMessage1.Decoder(empty_frame)
        @test isempty(
            BasicVariableLength.TestMessage1.encryptedNewPassword(empty_decoder)
        )
        @test SBE.sbe_regions(empty_frame)[2] === empty_payload
    end

    @testset "Schema length validation" begin
        prefix = zeros(UInt8, 9)
        encoder = BasicVariableLength.TestMessage1.Encoder(prefix)
        @test_throws ArgumentError begin
            BasicVariableLength.TestMessage1.encryptedNewPassword_external!(
                encoder,
                zeros(UInt8, 255)
            )
        end
        @test_throws ArgumentError begin
            @inbounds(
                BasicVariableLength.TestMessage1.encryptedNewPassword_external!(
                    encoder,
                    zeros(UInt8, 255)
                )
            )
        end
    end

    @testset "Nested frames" begin
        payload = UInt8[0xde, 0xad, 0xbe, 0xef]

        inner_prefix = zeros(UInt8, 12)
        inner_encoder = Issue488Schema.Issue488.Encoder(inner_prefix)
        inner_frame =
            Issue488Schema.Issue488.varData_external!(inner_encoder, payload)

        outer_prefix = zeros(UInt8, 12)
        outer_encoder = Issue488Schema.Issue488.Encoder(outer_prefix)
        outer_frame =
            Issue488Schema.Issue488.varData_external!(
                outer_encoder,
                inner_frame
            )

        @test length(SBE.sbe_regions(outer_frame)) == 3
        @test SBE.sbe_regions(outer_frame)[3] === payload

        contiguous = zeros(UInt8, length(outer_frame))
        contiguous_encoder = Issue488Schema.Issue488.Encoder(contiguous)
        Issue488Schema.Issue488.varData!(
            contiguous_encoder,
            collect(inner_frame)
        )
        @test collect(outer_frame) == contiguous

        outer_decoder = Issue488Schema.Issue488.Decoder(outer_frame)
        nested_bytes = Issue488Schema.Issue488.varData(outer_decoder)
        @test nested_bytes isa SBE.SbeFrame

        inner_decoder = Issue488Schema.Issue488.Decoder(nested_bytes)
        @test collect(Issue488Schema.Issue488.varData(inner_decoder)) == payload
    end

    @testset "Nonzero frame offsets" begin
        transport_prefix = fill(UInt8(0xaa), 5)
        payload = UInt8[0x10, 0x20]
        buffer = vcat(transport_prefix, zeros(UInt8, 12))
        encoder = Issue488Schema.Issue488.Encoder(buffer, 5)
        frame = Issue488Schema.Issue488.varData_external!(encoder, payload)

        @test SBE.sbe_frame_offset(encoder) == 5
        @test SBE.sbe_frame_length(encoder) == 14
        @test length(SBE.sbe_prefix(frame)) == 12
        @test collect(SBE.sbe_prefix(frame)) == buffer[6:17]
        @test all(==(0xaa), buffer[1:5])
    end
end
