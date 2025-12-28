using Test

@testset "Issue967 Optional Composite Fields" begin
    buffer = zeros(UInt8, 512)
    header = Issue967.MessageHeader.Encoder(buffer, 0)
    enc = Issue967.MDInstrumentDefinitionFX63.Encoder(typeof(buffer))
    Issue967.MDInstrumentDefinitionFX63.wrap_and_apply_header!(enc, buffer, 0; header=header)

    comp = Issue967.MDInstrumentDefinitionFX63.altMinPriceIncrement(enc)
    Issue967.PRICENULL9.mantissa!(comp, Int64(100))

    dec = Issue967.MDInstrumentDefinitionFX63.Decoder(typeof(buffer))
    Issue967.MDInstrumentDefinitionFX63.wrap!(dec, buffer, 0)
    comp_dec = Issue967.MDInstrumentDefinitionFX63.altMinPriceIncrement(dec)
    @test Issue967.PRICENULL9.mantissa(comp_dec) == Int64(100)
    @test Issue967.PRICENULL9.exponent(comp_dec) == Int8(-9)

    dec12 = Issue967.MDInstrumentDefinitionFX63.Decoder(typeof(buffer))
    dec12.position_ptr = SBE.PositionPointer()
    Issue967.MDInstrumentDefinitionFX63.wrap!(dec12, buffer, 0, UInt16(0), UInt16(12))
    @test Issue967.MDInstrumentDefinitionFX63.altMinPriceIncrement_in_acting_version(dec12)
    @test !Issue967.MDInstrumentDefinitionFX63.altPriceIncrementConstraint_in_acting_version(dec12)

    dec13 = Issue967.MDInstrumentDefinitionFX63.Decoder(typeof(buffer))
    dec13.position_ptr = SBE.PositionPointer()
    Issue967.MDInstrumentDefinitionFX63.wrap!(dec13, buffer, 0, UInt16(0), UInt16(13))
    @test Issue967.MDInstrumentDefinitionFX63.altPriceIncrementConstraint_in_acting_version(dec13)
end
