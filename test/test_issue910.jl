using Test

@testset "Issue910 Yield Identifier" begin
    buffer = zeros(UInt8, 128)
    header = Issue910.MessageHeader.Encoder(buffer, 0)
    enc = Issue910.Issue910Field.Encoder(typeof(buffer))
    Issue910.Issue910Field.wrap_and_apply_header!(enc, buffer, 0; header=header)
    Issue910.Issue910Field.yield!(enc, UInt64(42))

    dec = Issue910.Issue910Field.Decoder(typeof(buffer))
    Issue910.Issue910Field.wrap!(dec, buffer, 0)
    @test Issue910.Issue910Field.yield(dec) == UInt64(42)
end

@testset "Issue910 Yield VarData" begin
    buffer = zeros(UInt8, 128)
    header = Issue910.MessageHeader.Encoder(buffer, 0)
    enc = Issue910.Issue910Vardata.Encoder(typeof(buffer))
    Issue910.Issue910Vardata.wrap_and_apply_header!(enc, buffer, 0; header=header)
    payload = Issue910.Issue910Vardata.yield(enc)
    Issue910.VarDataEncoding.length!(payload, UInt8(1))
    Issue910.VarDataEncoding.varData!(payload, UInt8('a'))

    dec = Issue910.Issue910Vardata.Decoder(typeof(buffer))
    Issue910.Issue910Vardata.wrap!(dec, buffer, 0)
    payload_dec = Issue910.Issue910Vardata.yield(dec)
    @test Issue910.VarDataEncoding.length(payload_dec) == UInt8(1)
    @test Char(Issue910.VarDataEncoding.varData(payload_dec)) == 'a'
end

@testset "Issue910 Yield Group" begin
    buffer = zeros(UInt8, 128)
    header = Issue910.MessageHeader.Encoder(buffer, 0)
    enc = Issue910.Issue910Group.Encoder(typeof(buffer))
    Issue910.Issue910Group.wrap_and_apply_header!(enc, buffer, 0; header=header)

    group_enc = Issue910.Issue910Group.yield!(enc, 1)
    Issue910.Issue910Group.Yield.next!(group_enc)
    Issue910.Issue910Group.Yield.whatever!(group_enc, UInt64(7))

    dec = Issue910.Issue910Group.Decoder(typeof(buffer))
    Issue910.Issue910Group.wrap!(dec, buffer, 0)
    group_dec = Issue910.Issue910Group.yield(dec)
    (item, _) = iterate(group_dec)
    @test Issue910.Issue910Group.Yield.whatever(item) == UInt64(7)
end

@testset "Issue910 Yield Group Field" begin
    buffer = zeros(UInt8, 128)
    header = Issue910.MessageHeader.Encoder(buffer, 0)
    enc = Issue910.Issue910GroupField.Encoder(typeof(buffer))
    Issue910.Issue910GroupField.wrap_and_apply_header!(enc, buffer, 0; header=header)

    group_enc = Issue910.Issue910GroupField.whatever!(enc, 1)
    Issue910.Issue910GroupField.Whatever.next!(group_enc)
    Issue910.Issue910GroupField.Whatever.yield!(group_enc, UInt64(11))

    dec = Issue910.Issue910GroupField.Decoder(typeof(buffer))
    Issue910.Issue910GroupField.wrap!(dec, buffer, 0)
    group_dec = Issue910.Issue910GroupField.whatever(dec)
    (item, _) = iterate(group_dec)
    @test Issue910.Issue910GroupField.Whatever.yield(item) == UInt64(11)
end

@testset "Issue910 Yield Enum/Set/Array" begin
    buffer = zeros(UInt8, 128)
    header = Issue910.MessageHeader.Encoder(buffer, 0)

    enc_enum = Issue910.Issue910Enum.Encoder(typeof(buffer))
    Issue910.Issue910Enum.wrap_and_apply_header!(enc_enum, buffer, 0; header=header)
    Issue910.Issue910Enum.yield!(enc_enum, Issue910.Enum_.B)
    dec_enum = Issue910.Issue910Enum.Decoder(typeof(buffer))
    Issue910.Issue910Enum.wrap!(dec_enum, buffer, 0)
    @test Issue910.Issue910Enum.yield(dec_enum) == Issue910.Enum_.B

    enc_set = Issue910.Issue910Set.Encoder(typeof(buffer))
    Issue910.Issue910Set.wrap_and_apply_header!(enc_set, buffer, 0; header=header)
    set_enc = Issue910.Issue910Set.yield(enc_set)
    Issue910.Set_.A!(set_enc, true)
    Issue910.Set_.C!(set_enc, true)
    dec_set = Issue910.Issue910Set.Decoder(typeof(buffer))
    Issue910.Issue910Set.wrap!(dec_set, buffer, 0)
    set_dec = Issue910.Issue910Set.yield(dec_set)
    @test Issue910.Set_.A(set_dec)
    @test Issue910.Set_.C(set_dec)

    enc_array = Issue910.Issue910Array.Encoder(typeof(buffer))
    Issue910.Issue910Array.wrap_and_apply_header!(enc_array, buffer, 0; header=header)
    arr = Issue910.Issue910Array.yield!(enc_array)
    copyto!(arr, Int32[1, 2, 3, 4, 5])
    dec_array = Issue910.Issue910Array.Decoder(typeof(buffer))
    Issue910.Issue910Array.wrap!(dec_array, buffer, 0)
    @test collect(Issue910.Issue910Array.yield(dec_array)) == Int32[1, 2, 3, 4, 5]

    enc_char = Issue910.Issue910CharArray.Encoder(typeof(buffer))
    Issue910.Issue910CharArray.wrap_and_apply_header!(enc_char, buffer, 0; header=header)
    Issue910.Issue910CharArray.yield!(enc_char, "hello")
    dec_char = Issue910.Issue910CharArray.Decoder(typeof(buffer))
    Issue910.Issue910CharArray.wrap!(dec_char, buffer, 0)
    @test String(Issue910.Issue910CharArray.yield(dec_char)) == "hello"
end
