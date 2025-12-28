using Test

@testset "Lower Case Bitset" begin
    buffer = zeros(UInt8, 64)
    header = LowerCaseBitset.MessageHeader.Encoder(buffer, 0)
    enc = LowerCaseBitset.SomeMessage.Encoder(typeof(buffer))
    LowerCaseBitset.SomeMessage.wrap_and_apply_header!(enc, buffer, 0; header=header)

    event = LowerCaseBitset.SomeMessage.myEvent(enc)
    LowerCaseBitset.EventType.a!(event, true)
    LowerCaseBitset.EventType.Bb!(event, true)
    LowerCaseBitset.EventType.ccc!(event, false)
    LowerCaseBitset.EventType.D!(event, true)
    LowerCaseBitset.EventType.eeEee!(event, true)

    dec = LowerCaseBitset.SomeMessage.Decoder(typeof(buffer))
    LowerCaseBitset.SomeMessage.wrap!(dec, buffer, 0)
    event_dec = LowerCaseBitset.SomeMessage.myEvent(dec)
    @test LowerCaseBitset.EventType.a(event_dec) == true
    @test LowerCaseBitset.EventType.Bb(event_dec) == true
    @test LowerCaseBitset.EventType.ccc(event_dec) == false
    @test LowerCaseBitset.EventType.D(event_dec) == true
    @test LowerCaseBitset.EventType.eeEee(event_dec) == true
end
