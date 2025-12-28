using Test
using SBE

# Load the generated CompositeElements schema
# Note: Run test/generate_test_schemas.jl first to generate this
include(joinpath(@__DIR__, "generated", "CompositeElements.jl"))

@testset "Nested Sets in Composites" begin
    @testset "Nested Set Definition - SetOne" begin
        # Test 1: Set module exists inside composite
        @test isdefined(CompositeElements.Outer, :SetOne)
        
        # Test 2: Set has Decoder and Encoder types
        @test isdefined(CompositeElements.Outer.SetOne, :Decoder)
        @test isdefined(CompositeElements.Outer.SetOne, :Encoder)
        @test isdefined(CompositeElements.Outer.SetOne, :AbstractSetOne)
        
        # Test 3: Set choice accessors exist
        @test hasmethod(CompositeElements.Outer.SetOne.Bit0, (CompositeElements.Outer.SetOne.Decoder,))
        @test hasmethod(CompositeElements.Outer.SetOne.Bit16, (CompositeElements.Outer.SetOne.Decoder,))
        @test hasmethod(CompositeElements.Outer.SetOne.Bit26, (CompositeElements.Outer.SetOne.Decoder,))
        @test hasmethod(CompositeElements.Outer.SetOne.Bit0!, (CompositeElements.Outer.SetOne.Encoder, Bool))
        @test hasmethod(CompositeElements.Outer.SetOne.Bit16!, (CompositeElements.Outer.SetOne.Encoder, Bool))
        @test hasmethod(CompositeElements.Outer.SetOne.Bit26!, (CompositeElements.Outer.SetOne.Encoder, Bool))
        
        # Test 4: Set utility functions exist
        @test hasmethod(CompositeElements.Outer.SetOne.clear!, (CompositeElements.Outer.SetOne.Encoder,))
        @test hasmethod(CompositeElements.Outer.SetOne.is_empty, (CompositeElements.Outer.SetOne.AbstractSetOne,))
        @test hasmethod(CompositeElements.Outer.SetOne.raw_value, (CompositeElements.Outer.SetOne.AbstractSetOne,))
    end
    
    @testset "Nested Set Field Accessor - setOne" begin
        # Test 1: Field accessor exists
        @test hasmethod(CompositeElements.Outer.setOne, (CompositeElements.Outer.Decoder,))
        @test hasmethod(CompositeElements.Outer.setOne, (CompositeElements.Outer.Encoder,))
        
        # Test 2: Correct offset for setOne (after enumOne=1 and zeroth=1, so offset=2)
        buffer = zeros(UInt8, 20)
        outer = CompositeElements.Outer.Decoder(buffer, 0, UInt16(0))
        @test CompositeElements.Outer.setOne_encoding_offset(outer) == 2
        @test CompositeElements.Outer.setOne_encoding_length(outer) == 4  # uint32 = 4 bytes
        
        # Test 3: Correct offset for inner composite (after enum=1, zeroth=1, set=4, so offset=6)
        @test CompositeElements.Outer.inner_encoding_offset(outer) == 6
    end
    
    @testset "Read/Write Nested Set" begin
        # Test basic set operations
        buffer = zeros(UInt8, 20)
        outer_enc = CompositeElements.Outer.Encoder(buffer, 0)
        
        # Get the set accessor
        set = CompositeElements.Outer.setOne(outer_enc)
        @test typeof(set) <: CompositeElements.Outer.SetOne.AbstractSetOne
        
        # Clear and verify empty
        CompositeElements.Outer.SetOne.clear!(set)
        @test CompositeElements.Outer.SetOne.is_empty(set) == true
        @test CompositeElements.Outer.SetOne.raw_value(set) == 0x00000000
        
        # Set individual bits
        CompositeElements.Outer.SetOne.Bit0!(set, true)
        @test CompositeElements.Outer.SetOne.Bit0(set) == true
        @test CompositeElements.Outer.SetOne.Bit16(set) == false
        @test CompositeElements.Outer.SetOne.Bit26(set) == false
        @test CompositeElements.Outer.SetOne.raw_value(set) == 0x00000001
        
        CompositeElements.Outer.SetOne.Bit16!(set, true)
        @test CompositeElements.Outer.SetOne.Bit0(set) == true
        @test CompositeElements.Outer.SetOne.Bit16(set) == true
        @test CompositeElements.Outer.SetOne.Bit26(set) == false
        @test CompositeElements.Outer.SetOne.raw_value(set) == 0x00010001
        
        CompositeElements.Outer.SetOne.Bit26!(set, true)
        @test CompositeElements.Outer.SetOne.Bit0(set) == true
        @test CompositeElements.Outer.SetOne.Bit16(set) == true
        @test CompositeElements.Outer.SetOne.Bit26(set) == true
        @test CompositeElements.Outer.SetOne.raw_value(set) == 0x04010001
        
        # Decode and verify
        outer_dec = CompositeElements.Outer.Decoder(buffer, 0, UInt16(0))
        set_dec = CompositeElements.Outer.setOne(outer_dec)
        @test CompositeElements.Outer.SetOne.Bit0(set_dec) == true
        @test CompositeElements.Outer.SetOne.Bit16(set_dec) == true
        @test CompositeElements.Outer.SetOne.Bit26(set_dec) == true
        @test CompositeElements.Outer.SetOne.raw_value(set_dec) == 0x04010001
        
        # Clear individual bits
        CompositeElements.Outer.SetOne.Bit16!(set, false)
        @test CompositeElements.Outer.SetOne.Bit0(set_dec) == true
        @test CompositeElements.Outer.SetOne.Bit16(set_dec) == false
        @test CompositeElements.Outer.SetOne.Bit26(set_dec) == true
    end
    
    @testset "Nested Set in Composite Used in Message" begin
        # Test that the nested set works when the composite is used in a message
        buffer = zeros(UInt8, 1000)
        msg_enc = CompositeElements.Msg.Encoder(typeof(buffer))
        CompositeElements.Msg.wrap_and_apply_header!(msg_enc, buffer, 0)
        
        # Get the outer composite
        outer = CompositeElements.Msg.structure(msg_enc)
        
        # Get the set from the composite
        set = CompositeElements.Outer.setOne(outer)
        
        # Set some bits
        CompositeElements.Outer.SetOne.clear!(set)
        CompositeElements.Outer.SetOne.Bit0!(set, true)
        CompositeElements.Outer.SetOne.Bit26!(set, true)
        
        # Decode and verify
        msg_dec = CompositeElements.Msg.Decoder(typeof(buffer))
        CompositeElements.Msg.wrap!(msg_dec, buffer, 0)
        outer_dec = CompositeElements.Msg.structure(msg_dec)
        set_dec = CompositeElements.Outer.setOne(outer_dec)
        
        @test CompositeElements.Outer.SetOne.Bit0(set_dec) == true
        @test CompositeElements.Outer.SetOne.Bit16(set_dec) == false
        @test CompositeElements.Outer.SetOne.Bit26(set_dec) == true
    end
    
    @testset "Nested Set Metadata Functions" begin
        buffer = zeros(UInt8, 20)
        outer = CompositeElements.Outer.Decoder(buffer, 0, UInt16(0))
        
        # Test metadata accessors
        @test CompositeElements.Outer.setOne_id(outer) == 0xffff
        @test CompositeElements.Outer.setOne_id(CompositeElements.Outer.Decoder) == 0xffff
        @test CompositeElements.Outer.setOne_since_version(outer) == 0
        @test CompositeElements.Outer.setOne_since_version(CompositeElements.Outer.Decoder) == 0
        @test CompositeElements.Outer.setOne_in_acting_version(outer) == true
        @test CompositeElements.Outer.setOne_encoding_offset(outer) == 2
        @test CompositeElements.Outer.setOne_encoding_offset(CompositeElements.Outer.Decoder) == 2
        @test CompositeElements.Outer.setOne_encoding_length(outer) == 4
        @test CompositeElements.Outer.setOne_encoding_length(CompositeElements.Outer.Decoder) == 4
    end
    
    @testset "All Nested Types Together - Enum, Set, Composite" begin
        # Test that all nested types work together correctly with proper offsets
        buffer = zeros(UInt8, 100)
        outer_enc = CompositeElements.Outer.Encoder(buffer, 0)
        
        # Set enum (offset 0, size 1)
        CompositeElements.Outer.enumOne!(outer_enc, CompositeElements.Outer.EnumOne.Value10)
        
        # Set primitive field (offset 1, size 1)
        CompositeElements.Outer.zeroth!(outer_enc, 42)
        
        # Set the set bits (offset 2, size 4)
        set = CompositeElements.Outer.setOne(outer_enc)
        CompositeElements.Outer.SetOne.Bit0!(set, true)
        CompositeElements.Outer.SetOne.Bit16!(set, true)
        
        # Set nested composite fields (offset 6, size 16)
        inner = CompositeElements.Outer.inner(outer_enc)
        CompositeElements.Outer.Inner.first!(inner, 123456789)
        CompositeElements.Outer.Inner.second!(inner, 987654321)
        
        # Decode and verify all fields
        outer_dec = CompositeElements.Outer.Decoder(buffer, 0, UInt16(0))
        
        @test CompositeElements.Outer.enumOne(outer_dec) == CompositeElements.Outer.EnumOne.Value10
        @test CompositeElements.Outer.zeroth(outer_dec) == 42
        
        set_dec = CompositeElements.Outer.setOne(outer_dec)
        @test CompositeElements.Outer.SetOne.Bit0(set_dec) == true
        @test CompositeElements.Outer.SetOne.Bit16(set_dec) == true
        @test CompositeElements.Outer.SetOne.Bit26(set_dec) == false
        
        inner_dec = CompositeElements.Outer.inner(outer_dec)
        @test CompositeElements.Outer.Inner.first(inner_dec) == 123456789
        @test CompositeElements.Outer.Inner.second(inner_dec) == 987654321
        
        # Verify total size
        expected_size = 1 + 1 + 4 + 16  # enum + zeroth + set + inner
        @test CompositeElements.Outer.sbe_encoded_length(outer_dec) == expected_size
    end
end
