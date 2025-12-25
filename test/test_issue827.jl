using Test

@testset "Issue827 Big-Endian Set" begin
    buffer = zeros(UInt8, 64)
    header = Issue827.MessageHeader.Encoder(buffer, 0)
    enc = Issue827.Test.Encoder(buffer, 0; header=header)

    set0 = Issue827.Test.set0(enc)
    Issue827.FlagsSet.Bit0!(set0, true)
    Issue827.FlagsSet.Bit35!(set0, true)

    dec = Issue827.Test.Decoder(buffer, 0)
    set0d = Issue827.Test.set0(dec)
    @test Issue827.FlagsSet.Bit0(set0d)
    @test Issue827.FlagsSet.Bit35(set0d)
end
