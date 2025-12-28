using Test

@testset "Embedded Length and Count" begin
    buffer = zeros(UInt8, 256)
    header = EmbeddedLengthAndCount.MessageHeader.Encoder(buffer, 0)

    enc1 = EmbeddedLengthAndCount.Message1.Encoder(typeof(buffer))
    EmbeddedLengthAndCount.Message1.wrap_and_apply_header!(enc1, buffer, 0; header=header)
    EmbeddedLengthAndCount.Message1.tag1!(enc1, UInt32(5))
    list_enc = EmbeddedLengthAndCount.Message1.listOrdGrp!(enc1, 2)
    EmbeddedLengthAndCount.Message1.ListOrdGrp.next!(list_enc)
    EmbeddedLengthAndCount.Message1.ListOrdGrp.clOrdID!(list_enc, "AAA")
    EmbeddedLengthAndCount.Message1.ListOrdGrp.next!(list_enc)
    EmbeddedLengthAndCount.Message1.ListOrdGrp.clOrdID!(list_enc, "BBB")

    dec1 = EmbeddedLengthAndCount.Message1.Decoder(typeof(buffer))
    EmbeddedLengthAndCount.Message1.wrap!(dec1, buffer, 0)
    @test EmbeddedLengthAndCount.Message1.tag1(dec1) == UInt32(5)
    list_dec = EmbeddedLengthAndCount.Message1.listOrdGrp(dec1)
    ord_ids = String[]
    for elem in list_dec
        push!(ord_ids, String(EmbeddedLengthAndCount.Message1.ListOrdGrp.clOrdID(elem)))
    end
    @test sort(ord_ids) == ["AAA", "BBB"]

    enc2 = EmbeddedLengthAndCount.Message2.Encoder(typeof(buffer))
    EmbeddedLengthAndCount.Message2.wrap_and_apply_header!(enc2, buffer, 0; header=header)
    EmbeddedLengthAndCount.Message2.tag1!(enc2, UInt32(9))
    EmbeddedLengthAndCount.Message2.encryptedPassword!(enc2, "secret")

    dec2 = EmbeddedLengthAndCount.Message2.Decoder(typeof(buffer))
    EmbeddedLengthAndCount.Message2.wrap!(dec2, buffer, 0)
    @test EmbeddedLengthAndCount.Message2.tag1(dec2) == UInt32(9)
    @test String(EmbeddedLengthAndCount.Message2.encryptedPassword(dec2)) == "secret"
end
