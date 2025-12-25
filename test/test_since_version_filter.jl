using Test

@testset "Since Version Filter" begin
    buffer = zeros(UInt8, 128)
    header = SinceVersionFilter.MessageHeader.Encoder(buffer, 0)
    enc = SinceVersionFilter.MessageWithSince.Encoder(buffer, 0; header=header)
    SinceVersionFilter.MessageWithSince.fieldSince0!(enc, Int32(1))

    SinceVersionFilter.MessageHeader.version!(header, UInt16(3))
    dec_v3 = SinceVersionFilter.MessageWithSince.Decoder(buffer, 0)
    @test !SinceVersionFilter.MessageWithSince.fieldSince4_in_acting_version(dec_v3)
    @test !SinceVersionFilter.MessageWithSince.fieldSince5_in_acting_version(dec_v3)
    @test !SinceVersionFilter.MessageWithSince.groupSince4_in_acting_version(dec_v3)
    @test !SinceVersionFilter.MessageWithSince.dataSince4_in_acting_version(dec_v3)

    SinceVersionFilter.MessageHeader.version!(header, UInt16(4))
    dec_v4 = SinceVersionFilter.MessageWithSince.Decoder(buffer, 0)
    @test SinceVersionFilter.MessageWithSince.fieldSince4_in_acting_version(dec_v4)
    @test !SinceVersionFilter.MessageWithSince.fieldSince5_in_acting_version(dec_v4)
    @test SinceVersionFilter.MessageWithSince.groupSince4_in_acting_version(dec_v4)
    @test SinceVersionFilter.MessageWithSince.dataSince4_in_acting_version(dec_v4)
end
