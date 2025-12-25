using Test

@testset "Group With Data" begin
    buffer = zeros(UInt8, 256)
    header = GroupWithData.MessageHeader.Encoder(buffer, 0)

    enc = GroupWithData.TestMessage1.Encoder(buffer, 0; header=header)
    GroupWithData.TestMessage1.tag1!(enc, UInt32(42))
    entries = GroupWithData.TestMessage1.entries!(enc, 1)
    GroupWithData.TestMessage1.Entries.next!(entries)
    GroupWithData.TestMessage1.Entries.tagGroup1!(entries, "ABC")
    GroupWithData.TestMessage1.Entries.tagGroup2!(entries, Int64(99))
    GroupWithData.TestMessage1.Entries.varDataField!(entries, "hi")

    dec = GroupWithData.TestMessage1.Decoder(buffer, 0)
    @test GroupWithData.TestMessage1.tag1(dec) == UInt32(42)
    entries_dec = GroupWithData.TestMessage1.entries(dec)
    elems = collect(entries_dec)
    @test length(elems) == 1
    elem = elems[1]
    @test GroupWithData.TestMessage1.Entries.tagGroup1(elem) == "ABC"
    @test GroupWithData.TestMessage1.Entries.tagGroup2(elem) == Int64(99)
    @test String(GroupWithData.TestMessage1.Entries.varDataField(elem)) == "hi"
end
