using Test
using SBE

@testset "Core API" begin
    @testset "Abstract type hierarchy" begin
        @test SBE.AbstractSbeEncodedType <: SBE.AbstractSbeField
        @test SBE.AbstractSbeCompositeType <: SBE.AbstractSbeField
        @test Baseline.Car.Decoder <: SBE.AbstractSbeMessage
        @test Baseline.Car.FuelFigures.Decoder <: SBE.AbstractSbeGroup
    end

    @testset "XML schema parsing" begin
        schema_path = joinpath(@__DIR__, "example-schema.xml")
        schema = SBE.parse_xml_schema_file(schema_path)

        @test schema isa SBE.XmlMessageSchema
        @test schema.id == 1
        @test schema.version == 0
        @test schema.package_name == "baseline"
        @test schema.byte_order == :littleEndian
        @test haskey(schema.types_by_name, "Engine")
        @test only(schema.messages).name == "Car"
    end
end
