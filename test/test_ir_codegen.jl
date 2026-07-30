using Test
using SBE

module SbeIrMacroWorldAgeHost
using SBE

const LOADED_NAME = SBE.@load_sbeir(
    "resources/ir-basic-schema.sbeir";
    module_name=:GeneratedFromSbeIr
)

function encode_then_decode_order_id(value::UInt64)
    buffer = zeros(UInt8, 64)
    encoder = GeneratedFromSbeIr.Order.Encoder(typeof(buffer))
    GeneratedFromSbeIr.Order.wrap_and_apply_header!(encoder, buffer, 0)
    GeneratedFromSbeIr.Order.orderId!(encoder, value)

    decoder = GeneratedFromSbeIr.Order.Decoder(typeof(buffer))
    GeneratedFromSbeIr.Order.wrap!(decoder, buffer, 0)
    return GeneratedFromSbeIr.Order.orderId(decoder)
end

end

module CheckedSbeIrMacroHost
using SBE

const LOADED_NAME = SBE.@load_sbeir(
    "resources/ir-basic-schema.sbeir";
    module_name=:CheckedFromSbeIr,
    precedence_checks=true,
)

end

@testset "IR Code Generation" begin
    ir_path = joinpath(@__DIR__, "resources", "ir-basic-schema.sbeir")
    ir = SBE.decode_ir(ir_path)

    @testset "String output" begin
        code_from_path = SBE.generate_from_ir(ir_path; module_name=:IrPathSchema)
        code_from_value = SBE.generate_from_ir(ir; module_name=:IrPathSchema)
        @test code_from_path == code_from_value
        @test occursin("module IrPathSchema", code_from_path)
        @test Meta.parseall(code_from_path) isa Expr
    end

    @testset "File output" begin
        mktempdir() do dir
            output_path = joinpath(dir, "nested", "GeneratedSchema.jl")
            @test SBE.generate_from_ir(
                ir_path,
                output_path;
                module_name=:IrFileSchema,
            ) == output_path
            @test isfile(output_path)
            @test occursin("module IrFileSchema", read(output_path, String))

            value_output_path = joinpath(dir, "GeneratedFromValue.jl")
            @test SBE.generate_from_ir(
                ir,
                value_output_path;
                module_name=:IrValueSchema,
            ) == value_output_path
            @test isfile(value_output_path)
        end
    end

    @testset "Macro expansion-time world age" begin
        @test SbeIrMacroWorldAgeHost.LOADED_NAME == :GeneratedFromSbeIr
        @test isdefined(SbeIrMacroWorldAgeHost, :GeneratedFromSbeIr)
        @test SbeIrMacroWorldAgeHost.encode_then_decode_order_id(UInt64(1234)) == UInt64(1234)
        @test CheckedSbeIrMacroHost.LOADED_NAME == :CheckedFromSbeIr
        buffer = zeros(UInt8, 64)
        codec = CheckedSbeIrMacroHost.CheckedFromSbeIr.Order
        encoder = codec.Encoder(buffer)
        codec.orderId!(encoder, UInt64(9))
        codec.note!(encoder, UInt8[])
        @test SBE.check_encoding_is_complete(encoder) === nothing
    end

    @testset "Invalid usage" begin
        @test_throws ArgumentError macroexpand(Main, :(SBE.@load_sbeir ir_path))
        @test_throws SystemError macroexpand(
            Main,
            :(SBE.@load_sbeir "resources/missing.sbeir"),
        )
        @test_throws ArgumentError macroexpand(
            Main,
            :(SBE.@load_sbeir(
                "resources/ir-basic-schema.sbeir";
                precedence_checks=enabled,
            )),
        )
    end
end
