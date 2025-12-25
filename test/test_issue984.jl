using Test

@testset "Issue984 Group Field SinceVersion" begin
    buffer = zeros(UInt8, 128)
    header = Issue984.MessageHeader.Encoder(buffer, 0)
    enc = Issue984.SimpleMessage.Encoder(buffer, 0; header=header)

    group_enc = Issue984.SimpleMessage.myGroup!(enc, 1)
    Issue984.SimpleMessage.MyGroup.next!(group_enc)
    Issue984.SimpleMessage.MyGroup.f1!(group_enc, "ABCD")
    Issue984.SimpleMessage.MyGroup.f2!(group_enc, "EFGHI")
    Issue984.SimpleMessage.MyGroup.f3!(group_enc, "JKLMNO")

    dec = Issue984.SimpleMessage.Decoder(buffer, 0)
    group_dec = Issue984.SimpleMessage.myGroup(dec)
    (item, _) = iterate(group_dec)
    @test String(Issue984.SimpleMessage.MyGroup.f1(item)) == "ABCD"
    @test String(Issue984.SimpleMessage.MyGroup.f2(item)) == "EFGHI"
    @test String(Issue984.SimpleMessage.MyGroup.f3(item)) == "JKLMNO"

    dec1 = Issue984.SimpleMessage.Decoder(buffer, 0, Ref(0), UInt16(0), UInt16(1))
    group_dec1 = Issue984.SimpleMessage.myGroup(dec1)
    @test !Issue984.SimpleMessage.MyGroup.f2_in_acting_version(group_dec1)
    @test !Issue984.SimpleMessage.MyGroup.f3_in_acting_version(group_dec1)
end
