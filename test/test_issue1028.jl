using Test

@testset "Issue1028 Set SinceVersion in Composite" begin
    buffer = zeros(UInt8, 64)
    header = Issue1028.MessageHeader.Encoder(buffer, 0)
    enc = Issue1028.ExecutionReportNew.Encoder(typeof(buffer))
    Issue1028.ExecutionReportNew.wrap_and_apply_header!(enc, buffer, 0; header=header)

    hdr = Issue1028.ExecutionReportNew.businessHeader(enc)
    set_enc = Issue1028.OutboundBusinessHeader.eventIndicator(hdr)
    Issue1028.EventIndicator.PossResend!(set_enc, true)

    dec = Issue1028.ExecutionReportNew.Decoder(typeof(buffer))
    Issue1028.ExecutionReportNew.wrap!(dec, buffer, 0)
    hdr_dec = Issue1028.ExecutionReportNew.businessHeader(dec)
    set_dec = Issue1028.OutboundBusinessHeader.eventIndicator(hdr_dec)
    @test Issue1028.EventIndicator.PossResend(set_dec)

    Issue1028.MessageHeader.version!(header, UInt16(3))
    dec3 = Issue1028.ExecutionReportNew.Decoder(typeof(buffer))
    Issue1028.ExecutionReportNew.wrap!(dec3, buffer, 0)
    hdr_dec3 = Issue1028.ExecutionReportNew.businessHeader(dec3)
    @test !Issue1028.OutboundBusinessHeader.eventIndicator_in_acting_version(hdr_dec3)
end
