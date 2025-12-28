using Test

@testset "Group With Constant Fields" begin
    buffer = zeros(UInt8, 256)
    header = GroupWithConstantFields.MessageHeader.Encoder(buffer, 0)
    enc = GroupWithConstantFields.ConstantsGalore.Encoder(typeof(buffer))
    GroupWithConstantFields.ConstantsGalore.wrap_and_apply_header!(enc, buffer, 0; header=header)

    GroupWithConstantFields.ConstantsGalore.a!(enc, UInt8(1))
    comp = GroupWithConstantFields.ConstantsGalore.e(enc)
    GroupWithConstantFields.CompositeWithConst.w!(comp, UInt8(3))

    group_enc = GroupWithConstantFields.ConstantsGalore.f!(enc, 1)
    GroupWithConstantFields.ConstantsGalore.F.next!(group_enc)
    GroupWithConstantFields.ConstantsGalore.F.g!(group_enc, UInt8(4))

    comp_group = GroupWithConstantFields.ConstantsGalore.F.h(group_enc)
    GroupWithConstantFields.CompositeWithConst.w!(comp_group, UInt8(6))

    dec = GroupWithConstantFields.ConstantsGalore.Decoder(typeof(buffer))
    GroupWithConstantFields.ConstantsGalore.wrap!(dec, buffer, 0)
    @test GroupWithConstantFields.ConstantsGalore.a(dec) == UInt8(1)
    @test GroupWithConstantFields.ConstantsGalore.b(dec) == UInt16(9000)
    @test GroupWithConstantFields.ConstantsGalore.c(dec) == GroupWithConstantFields.Model.C
    @test GroupWithConstantFields.ConstantsGalore.d(dec) == UInt16(9000)

    comp_dec = GroupWithConstantFields.ConstantsGalore.e(dec)
    @test GroupWithConstantFields.CompositeWithConst.w(comp_dec) == UInt8(3)
    @test GroupWithConstantFields.CompositeWithConst.x(comp_dec) == UInt8(250)
    @test GroupWithConstantFields.CompositeWithConst.y(comp_dec) == UInt16(9000)

    group_dec = GroupWithConstantFields.ConstantsGalore.f(dec)
    elems = collect(group_dec)
    @test length(elems) == 1
    elem = elems[1]
    @test GroupWithConstantFields.ConstantsGalore.F.g(elem) == UInt8(4)
    @test GroupWithConstantFields.ConstantsGalore.F.i(elem) == UInt16(9000)
    @test GroupWithConstantFields.ConstantsGalore.F.j(elem) == UInt16(9000)
    @test GroupWithConstantFields.ConstantsGalore.F.k(elem) == GroupWithConstantFields.Model.C
    @test GroupWithConstantFields.ConstantsGalore.F.l(elem) == "Huzzah"

    comp_dec_group = GroupWithConstantFields.ConstantsGalore.F.h(elem)
    @test GroupWithConstantFields.CompositeWithConst.w(comp_dec_group) == UInt8(6)
    @test GroupWithConstantFields.CompositeWithConst.x(comp_dec_group) == UInt8(250)
    @test GroupWithConstantFields.CompositeWithConst.y(comp_dec_group) == UInt16(9000)
end
