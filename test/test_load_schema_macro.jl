using Test
using SBE

module LoadSchemaBasicHost
using SBE

const BASELINE_NAME = SBE.@load_schema "example-schema.xml"
const BASELINE_MODULE = Baseline
const BASELINE_NAME_AGAIN = SBE.@load_schema "example-schema.xml"
const EXTENSION_NAME = SBE.@load_schema "example-extension-schema.xml"

end


module LoadSchemaOverrideHost
using SBE

const LOADED_NAME = SBE.@load_schema(
    "example-schema.xml";
    module_name=:CustomSchemaOverride,
)

end


module LoadSchemaStatementHost
using SBE

SBE.@load_schema "example-extension-schema.xml"
const MODULE_PRESENT = isdefined(@__MODULE__, :Extension)

end


module LoadSchemaWorldAgeHost
using SBE

const LOADED_NAME = SBE.@load_schema(
    "resources/ir-basic-schema.xml";
    module_name=:ExpansionTimeSchema,
)

function encode_then_decode_order_id(value::UInt64)
    buffer = zeros(UInt8, 64)
    encoder = ExpansionTimeSchema.Order.Encoder(typeof(buffer))
    ExpansionTimeSchema.Order.wrap_and_apply_header!(encoder, buffer, 0)
    ExpansionTimeSchema.Order.orderId!(encoder, value)

    decoder = ExpansionTimeSchema.Order.Decoder(typeof(buffer))
    ExpansionTimeSchema.Order.wrap!(decoder, buffer, 0)
    return ExpansionTimeSchema.Order.orderId(decoder)
end

end


@testset "@load_schema" begin
    @testset "Module naming and override" begin
        @test SBE.module_name_from_package("SBE tests-1") == :SBETests1
        @test LoadSchemaBasicHost.BASELINE_NAME == :Baseline
        @test LoadSchemaBasicHost.EXTENSION_NAME == :Extension
        @test isdefined(LoadSchemaBasicHost, :Baseline)
        @test isdefined(LoadSchemaBasicHost, :Extension)

        @test LoadSchemaOverrideHost.LOADED_NAME == :CustomSchemaOverride
        @test isdefined(LoadSchemaOverrideHost, :CustomSchemaOverride)
    end

    @testset "Repeated loading" begin
        @test LoadSchemaBasicHost.BASELINE_NAME_AGAIN == :Baseline
        @test LoadSchemaBasicHost.Baseline === LoadSchemaBasicHost.BASELINE_MODULE
    end

    @testset "Statement form" begin
        @test LoadSchemaStatementHost.MODULE_PRESENT
    end

    @testset "Expansion-time world age" begin
        @test LoadSchemaWorldAgeHost.LOADED_NAME == :ExpansionTimeSchema
        @test isdefined(LoadSchemaWorldAgeHost, :ExpansionTimeSchema)
        @test LoadSchemaWorldAgeHost.encode_then_decode_order_id(UInt64(42)) == UInt64(42)
    end

    @testset "Invalid usage" begin
        @test_throws SystemError macroexpand(
            Main,
            :(SBE.@load_schema "non_existent_file.xml"),
        )
        @test_throws ArgumentError macroexpand(Main, :(SBE.@load_schema schema_path))

        literal_path = abspath(joinpath(@__DIR__, "resources", "ir-basic-schema.xml"))
        invalid_host = Module(gensym(:InvalidSchemaLoadHost))
        Core.eval(invalid_host, :(using SBE))
        nested_call = :(
            function invalid_nested_schema_loader()
                SBE.@load_schema($literal_path; module_name=:InvalidNestedSchemaLoad)
            end
        )
        @test_throws ErrorException Core.eval(invalid_host, nested_call)
    end
end
