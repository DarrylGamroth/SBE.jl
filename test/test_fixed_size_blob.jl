using Test

@testset "Fixed-Size Blob Encoding" begin
    buffer = zeros(UInt8, 128)
    header = ExtensionSchema.MessageHeader.Encoder(buffer, 0)
    enc = ExtensionSchema.TestMessage2.Encoder(typeof(buffer))
    ExtensionSchema.TestMessage2.wrap_and_apply_header!(enc, buffer, 0; header=header)

    src = Vector{UInt8}(codeunits("  **DATA**  "))

    # Every byte written, every byte read
    dest = ExtensionSchema.TestMessage2.tag6!(enc)
    fill!(dest, 0x00)
    copyto!(dest, 1, src, 3, 8)
    dec = ExtensionSchema.TestMessage2.Decoder(typeof(buffer))
    ExtensionSchema.TestMessage2.wrap!(dec, buffer, 0)
    decoded = ExtensionSchema.TestMessage2.tag6(dec)
    @test decoded == src[3:10]

    # Every byte written, less bytes read
    @test decoded[1:6] == src[3:8]

    # Less bytes written (padding), every byte read
    dest = ExtensionSchema.TestMessage2.tag6!(enc)
    fill!(dest, 0x00)
    copyto!(dest, 1, src, 3, 6)
    dec = ExtensionSchema.TestMessage2.Decoder(typeof(buffer))
    ExtensionSchema.TestMessage2.wrap!(dec, buffer, 0)
    decoded = ExtensionSchema.TestMessage2.tag6(dec)
    @test decoded == vcat(src[3:8], UInt8[0x00, 0x00])
end
