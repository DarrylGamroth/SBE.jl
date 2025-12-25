using Test

@testset "Java Generator Parity (Schemas)" begin
    @testset "Issue505 constant char arrays" begin
        buffer = zeros(UInt8, 64)
        header = Issue505.MessageHeader.Encoder(buffer, 0)
        _ = Issue505.SomeMessage.Encoder(buffer, 0; header=header)
        dec = Issue505.SomeMessage.Decoder(buffer, 0)

        @test Issue505.SomeMessage.sourceOne(dec) == UInt8('C')
        @test Issue505.SomeMessage.sourceTwo(dec) == UInt8('D')
        @test Issue505.SomeMessage.sourceThree(dec) == "EF"
        @test Issue505.SomeMessage.sourceFour(dec) == "GH"
    end

    @testset "Issue889 enum null value" begin
        buffer = zeros(UInt8, 64)
        header = Issue889.MessageHeader.Encoder(buffer, 0)
        _ = Issue889.EnumMessage.Encoder(buffer, 0; header=header)
        dec = Issue889.EnumMessage.Decoder(buffer, 0)

        @test UInt8(Issue889.LotType.NULL_VALUE) == UInt8(0)
        @test Issue889.EnumMessage.field1(dec) == Issue889.LotType.NULL_VALUE
    end

    @testset "ValueRef lower-case enum" begin
        buffer = zeros(UInt8, 64)
        header = ValueRefLowerCaseEnum.MessageHeader.Encoder(buffer, 0)
        _ = ValueRefLowerCaseEnum.SomeMessage.Encoder(buffer, 0; header=header)
        dec = ValueRefLowerCaseEnum.SomeMessage.Decoder(buffer, 0)

        @test ValueRefLowerCaseEnum.SomeMessage.engineType(dec) == ValueRefLowerCaseEnum.EngineType.gas
    end
end
