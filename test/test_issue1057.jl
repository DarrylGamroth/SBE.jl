using Test

@testset "Issue1057 Set + Ref Composite" begin
    buffer = zeros(UInt8, 64)
    header = Issue1057.MessageHeader.Encoder(buffer, 0)
    enc = Issue1057.ExecutionReportNew.Encoder(typeof(buffer))
    Issue1057.ExecutionReportNew.wrap_and_apply_header!(enc, buffer, 0; header=header)

    hdr = Issue1057.ExecutionReportNew.businessHeader(enc)
    Issue1057.OutboundBusinessHeader.sessionID!(hdr, UInt32(99))
    set_enc = Issue1057.OutboundBusinessHeader.eventIndicator(hdr)
    Issue1057.EventIndicator.PossResend!(set_enc, true)

    dec = Issue1057.ExecutionReportNew.Decoder(typeof(buffer))
    Issue1057.ExecutionReportNew.wrap!(dec, buffer, 0)
    hdr_dec = Issue1057.ExecutionReportNew.businessHeader(dec)
    @test Issue1057.OutboundBusinessHeader.sessionID(hdr_dec) == UInt32(99)
    set_dec = Issue1057.OutboundBusinessHeader.eventIndicator(hdr_dec)
    @test Issue1057.EventIndicator.PossResend(set_dec)

    Issue1057.MessageHeader.version!(header, UInt16(3))
    dec3 = Issue1057.ExecutionReportNew.Decoder(typeof(buffer))
    Issue1057.ExecutionReportNew.wrap!(dec3, buffer, 0)
    hdr_dec3 = Issue1057.ExecutionReportNew.businessHeader(dec3)
    @test Issue1057.OutboundBusinessHeader.sessionID(hdr_dec3) == UInt32(99)
    @test !Issue1057.OutboundBusinessHeader.eventIndicator_in_acting_version(hdr_dec3)
end
