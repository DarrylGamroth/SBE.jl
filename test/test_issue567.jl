using Test

@testset "Issue567 Group Count Width" begin
    buffer = zeros(UInt8, 64)
    header = Issue567.MessageHeader.Encoder(buffer, 0)
    enc = Issue567.Issue567.Encoder(buffer, 0; header=header)

    group_enc = Issue567.Issue567.group!(enc, 1)
    @test group_enc.count isa UInt32
    @test length(group_enc) == 1

    Issue567.Issue567.Group.next!(group_enc)
    Issue567.Issue567.Group.groupField!(group_enc, Int32(123))

    dec = Issue567.Issue567.Decoder(buffer, 0)
    group_dec = Issue567.Issue567.group(dec)
    @test group_dec.count isa UInt32
    @test length(group_dec) == 1

    elem = iterate(group_dec)
    @test elem !== nothing
    (item, _) = elem
    @test Issue567.Issue567.Group.groupField(item) == Int32(123)
end
