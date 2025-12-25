using Test

@testset "Nested Composite Name" begin
    buffer = zeros(UInt8, 128)
    header = NestedCompositeName.MessageHeader.Encoder(buffer, 0)
    enc = NestedCompositeName.MyMessage.Encoder(buffer, 0; header=header)

    comp = NestedCompositeName.MyMessage.irrelevantField(enc)
    nested = NestedCompositeName.MyComposite.myFieldName(comp)
    NestedCompositeName.MyNestedComposite.irrelevantField!(nested, UInt16(123))

    dec = NestedCompositeName.MyMessage.Decoder(buffer, 0)
    comp_dec = NestedCompositeName.MyMessage.irrelevantField(dec)
    nested_dec = NestedCompositeName.MyComposite.myFieldName(comp_dec)
    @test NestedCompositeName.MyNestedComposite.irrelevantField(nested_dec) == UInt16(123)
end
