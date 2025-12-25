using Test

@testset "Constant Enum Fields" begin
    buffer = zeros(UInt8, 128)
    header = ConstantEnumFields.MessageHeader.Encoder(buffer, 0)
    enc = ConstantEnumFields.ConstantEnums.Encoder(buffer, 0; header=header)

    group_enc = ConstantEnumFields.ConstantEnums.f!(enc, 1)
    ConstantEnumFields.ConstantEnums.F.next!(group_enc)

    dec = ConstantEnumFields.ConstantEnums.Decoder(buffer, 0)
    @test ConstantEnumFields.ConstantEnums.c(dec) == ConstantEnumFields.Model.C

    group_dec = ConstantEnumFields.ConstantEnums.f(dec)
    elems = collect(group_dec)
    @test length(elems) == 1
    @test ConstantEnumFields.ConstantEnums.F.k(elems[1]) == ConstantEnumFields.Model.C
end
