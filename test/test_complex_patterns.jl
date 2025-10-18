using Test
using SBE

@testset "Complex Group & VarData Patterns" begin
    # Use pre-generated OrderCheck module (loaded by runtests.jl)
    
    @testset "Nested Groups - 3 Levels Deep" begin
        # Test deeply nested group structure based on NestedGroups message
        # Schema: a -> b -> (d, f) where d and f are nested groups
        # Java: allowsEncodingNestedGroupsInSchemaDefinedOrder
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.NestedGroups.Encoder(buffer)
        
        # Set top-level field
        Order_check.NestedGroups.a!(enc, 42)
        
        # Create outer group b with 1 element
        b_enc = Order_check.NestedGroups.b!(enc, 1)
        Order_check.NestedGroups.B.next!(b_enc)
        Order_check.NestedGroups.B.c!(b_enc, 1)
        
        # Create nested group d within b (2 elements)
        d_enc = Order_check.NestedGroups.B.d!(b_enc, 2)
        Order_check.NestedGroups.B.D.next!(d_enc)
        Order_check.NestedGroups.B.D.e!(d_enc, 2)
        Order_check.NestedGroups.B.D.next!(d_enc)
        Order_check.NestedGroups.B.D.e!(d_enc, 3)
        
        # Create sibling nested group f within b (1 element)
        f_enc = Order_check.NestedGroups.B.f!(b_enc, 1)
        Order_check.NestedGroups.B.F.next!(f_enc)
        Order_check.NestedGroups.B.F.g!(f_enc, 4)
        
        # Create top-level group h (1 element)
        h_enc = Order_check.NestedGroups.h!(enc, 1)
        Order_check.NestedGroups.H.next!(h_enc)
        Order_check.NestedGroups.H.i!(h_enc, 5)
        
        # Decode and verify the nested structure
        dec = Order_check.NestedGroups.Decoder(buffer)
        @test Order_check.NestedGroups.a(dec) == 42
        
        # Decode outer group b
    b_dec = Order_check.NestedGroups.b(dec)
    @test length(b_dec) == 1
    Order_check.NestedGroups.B.next!(b_dec)
    @test Order_check.NestedGroups.B.c(b_dec) == 1
    # Decode nested group d
    d_dec = Order_check.NestedGroups.B.d(b_dec)
    @test length(d_dec) == 2
    Order_check.NestedGroups.B.D.next!(d_dec)
    @test Order_check.NestedGroups.B.D.e(d_dec) == 2
    Order_check.NestedGroups.B.D.next!(d_dec)
    @test Order_check.NestedGroups.B.D.e(d_dec) == 3
    # Decode sibling nested group f
    f_dec = Order_check.NestedGroups.B.f(b_dec)
    @test length(f_dec) == 1
    Order_check.NestedGroups.B.F.next!(f_dec)
    @test Order_check.NestedGroups.B.F.g(f_dec) == 4
    # Decode top-level group h
    h_dec = Order_check.NestedGroups.h(dec)
    @test length(h_dec) == 1
    Order_check.NestedGroups.H.next!(h_dec)
    @test Order_check.NestedGroups.H.i(h_dec) == 5
    end
    
    @testset "VarData Inside Groups" begin
        # Test variable-length data within group elements
        # Java: allowsEncodingAndDecodingVariableLengthFieldInsideGroupInSchemaDefinedOrder
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.VarLengthInsideGroup.Encoder(buffer)
        
        # Set top-level field
        Order_check.VarLengthInsideGroup.a!(enc, 100)
        
        # Create group with 2 elements, each containing vardata
        b_enc = Order_check.VarLengthInsideGroup.b!(enc, 2)
        
        # First element with vardata
        Order_check.VarLengthInsideGroup.B.next!(b_enc)
        Order_check.VarLengthInsideGroup.B.c!(b_enc, 1)
        Order_check.VarLengthInsideGroup.B.d!(b_enc, "abc")
        
        # Second element with vardata
        Order_check.VarLengthInsideGroup.B.next!(b_enc)
        Order_check.VarLengthInsideGroup.B.c!(b_enc, 2)
        Order_check.VarLengthInsideGroup.B.d!(b_enc, "defgh")
        
        # Top-level vardata
        Order_check.VarLengthInsideGroup.e!(enc, "xyz")
        
        # Decode and verify
        dec = Order_check.VarLengthInsideGroup.Decoder(buffer)
        @test Order_check.VarLengthInsideGroup.a(dec) == 100
        
    b_dec = Order_check.VarLengthInsideGroup.b(dec)
    @test length(b_dec) == 2
    Order_check.VarLengthInsideGroup.B.next!(b_dec)
    @test Order_check.VarLengthInsideGroup.B.c(b_dec) == 1
    @test Order_check.VarLengthInsideGroup.B.d(b_dec) == "abc"
    Order_check.VarLengthInsideGroup.B.next!(b_dec)
    @test Order_check.VarLengthInsideGroup.B.c(b_dec) == 2
    @test Order_check.VarLengthInsideGroup.B.d(b_dec) == "defgh"
    # Top-level vardata
    @test Order_check.VarLengthInsideGroup.e(dec) == "xyz"
    end
    
    @testset "VarData in Nested Groups" begin
        # Test vardata in deeply nested groups
        # Java: NestedGroupWithVarLength message tests
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.NestedGroupWithVarLength.Encoder(buffer)
        
        Order_check.NestedGroupWithVarLength.a!(enc, 42)
        
        # Outer group
        b_enc = Order_check.NestedGroupWithVarLength.b!(enc, 1)
        Order_check.NestedGroupWithVarLength.B.next!(b_enc)
        Order_check.NestedGroupWithVarLength.B.c!(b_enc, 100)
        
        # Nested group with vardata
        d_enc = Order_check.NestedGroupWithVarLength.B.d!(b_enc, 2)
        
        Order_check.NestedGroupWithVarLength.B.D.next!(d_enc)
        Order_check.NestedGroupWithVarLength.B.D.e!(d_enc, 1)
        Order_check.NestedGroupWithVarLength.B.D.f!(d_enc, "first")
        
        Order_check.NestedGroupWithVarLength.B.D.next!(d_enc)
        Order_check.NestedGroupWithVarLength.B.D.e!(d_enc, 2)
        Order_check.NestedGroupWithVarLength.B.D.f!(d_enc, "second")
        
        # Decode and verify
        dec = Order_check.NestedGroupWithVarLength.Decoder(buffer)
        @test Order_check.NestedGroupWithVarLength.a(dec) == 42
        
    b_dec = Order_check.NestedGroupWithVarLength.b(dec)
    Order_check.NestedGroupWithVarLength.B.next!(b_dec)
    @test Order_check.NestedGroupWithVarLength.B.c(b_dec) == 100
    d_dec = Order_check.NestedGroupWithVarLength.B.d(b_dec)
    Order_check.NestedGroupWithVarLength.B.D.next!(d_dec)
    @test Order_check.NestedGroupWithVarLength.B.D.e(d_dec) == 1
    @test Order_check.NestedGroupWithVarLength.B.D.f(d_dec) == "first"
    Order_check.NestedGroupWithVarLength.B.D.next!(d_dec)
    @test Order_check.NestedGroupWithVarLength.B.D.e(d_dec) == 2
    @test Order_check.NestedGroupWithVarLength.B.D.f(d_dec) == "second"
    end
    
    @testset "Arrays Inside Groups" begin
        # Test fixed-size arrays within group elements
        # Java: allowsEncodingAndDecodingArrayInsideGroup
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.ArrayInsideGroup.Encoder(buffer)
        
        # Set top-level array field (ipV4Address is 4-byte array)
        Order_check.ArrayInsideGroup.a!(enc, UInt8[192, 168, 1, 1])
        
        # Create group with array fields
        b_enc = Order_check.ArrayInsideGroup.b!(enc, 2)
        
        Order_check.ArrayInsideGroup.B.next!(b_enc)
        Order_check.ArrayInsideGroup.B.c!(b_enc, UInt8[10, 0, 0, 1])
        
        Order_check.ArrayInsideGroup.B.next!(b_enc)
        Order_check.ArrayInsideGroup.B.c!(b_enc, UInt8[10, 0, 0, 2])
        
        # Decode and verify
        dec = Order_check.ArrayInsideGroup.Decoder(buffer)
        a_val = Order_check.ArrayInsideGroup.a(dec)
        @test a_val == UInt8[192, 168, 1, 1]
        
    b_dec = Order_check.ArrayInsideGroup.b(dec)
    Order_check.ArrayInsideGroup.B.next!(b_dec)
    @test Order_check.ArrayInsideGroup.B.c(b_dec) == UInt8[10, 0, 0, 1]
    Order_check.ArrayInsideGroup.B.next!(b_dec)
    @test Order_check.ArrayInsideGroup.B.c(b_dec) == UInt8[10, 0, 0, 2]
    end
    
    @testset "Composites Inside Groups" begin
        # Test composite types within group elements
        # Java: allowsEncodingAndDecodingCompositeInsideGroupInSchemaDefinedOrder
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.CompositeInsideGroup.Encoder(buffer)
        
        # Set top-level composite field (point has x, y)
        a_comp = Order_check.CompositeInsideGroup.a(enc)
        Order_check.Point.x!(a_comp, 10)
        Order_check.Point.y!(a_comp, 20)
        
        # Create group with composite fields
        b_enc = Order_check.CompositeInsideGroup.b!(enc, 2)
        
        Order_check.CompositeInsideGroup.B.next!(b_enc)
        c1_comp = Order_check.CompositeInsideGroup.B.c(b_enc)
        Order_check.Point.x!(c1_comp, 100)
        Order_check.Point.y!(c1_comp, 200)
        
        Order_check.CompositeInsideGroup.B.next!(b_enc)
        c2_comp = Order_check.CompositeInsideGroup.B.c(b_enc)
        Order_check.Point.x!(c2_comp, 300)
        Order_check.Point.y!(c2_comp, 400)
        
        # Decode and verify
        dec = Order_check.CompositeInsideGroup.Decoder(buffer)
        a_val = Order_check.CompositeInsideGroup.a(dec)
        @test Order_check.Point.x(a_val) == 10
        @test Order_check.Point.y(a_val) == 20
        
    b_dec = Order_check.CompositeInsideGroup.b(dec)
    Order_check.CompositeInsideGroup.B.next!(b_dec)
    c1 = Order_check.CompositeInsideGroup.B.c(b_dec)
    @test Order_check.Point.x(c1) == 100
    @test Order_check.Point.y(c1) == 200
    Order_check.CompositeInsideGroup.B.next!(b_dec)
    c2 = Order_check.CompositeInsideGroup.B.c(b_dec)
    @test Order_check.Point.x(c2) == 300
    @test Order_check.Point.y(c2) == 400
    end
    
    @testset "Enums Inside Groups" begin
        # Test enum types within group elements
        # Java: EnumInsideGroup tests
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.EnumInsideGroup.Encoder(buffer)
        
        # Set top-level enum
        Order_check.EnumInsideGroup.a!(enc, Order_check.Direction.BUY)
        
        # Create group with enum fields
        b_enc = Order_check.EnumInsideGroup.b!(enc, 2)
        
        Order_check.EnumInsideGroup.B.next!(b_enc)
        Order_check.EnumInsideGroup.B.c!(b_enc, Order_check.Direction.BUY)
        
        Order_check.EnumInsideGroup.B.next!(b_enc)
        Order_check.EnumInsideGroup.B.c!(b_enc, Order_check.Direction.SELL)
        
        # Decode and verify
        dec = Order_check.EnumInsideGroup.Decoder(buffer)
        @test Order_check.EnumInsideGroup.a(dec) == Order_check.Direction.BUY
        
    b_dec = Order_check.EnumInsideGroup.b(dec)
    Order_check.EnumInsideGroup.B.next!(b_dec)
    @test Order_check.EnumInsideGroup.B.c(b_dec) == Order_check.Direction.BUY
    Order_check.EnumInsideGroup.B.next!(b_dec)
    @test Order_check.EnumInsideGroup.B.c(b_dec) == Order_check.Direction.SELL
    end
    
    @testset "BitSets Inside Groups" begin
        # Test bitset types within group elements
        # Java: BitSetInsideGroup tests
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.BitSetInsideGroup.Encoder(buffer)
        
        # Set top-level bitset
        Order_check.BitSetInsideGroup.a!(enc, Set([Order_check.Flags.guacamole]))
        
        # Create group with bitset fields
        b_enc = Order_check.BitSetInsideGroup.b!(enc, 2)
        
        Order_check.BitSetInsideGroup.B.next!(b_enc)
        Order_check.BitSetInsideGroup.B.c!(b_enc, Set([Order_check.Flags.cheese]))
        
        Order_check.BitSetInsideGroup.B.next!(b_enc)
        Order_check.BitSetInsideGroup.B.c!(b_enc, Set([Order_check.Flags.guacamole, Order_check.Flags.sourCream]))
        
        # Decode and verify
        dec = Order_check.BitSetInsideGroup.Decoder(buffer)
        a_set = Order_check.BitSetInsideGroup.a(dec)
        @test Order_check.Flags.guacamole(a_set)
        @test !Order_check.Flags.cheese(a_set)
        
    b_dec = Order_check.BitSetInsideGroup.b(dec)
    Order_check.BitSetInsideGroup.B.next!(b_dec)
    c1_set = Order_check.BitSetInsideGroup.B.c(b_dec)
    @test Order_check.Flags.cheese(c1_set)
    Order_check.BitSetInsideGroup.B.next!(b_dec)
    c2_set = Order_check.BitSetInsideGroup.B.c(b_dec)
    @test Order_check.Flags.guacamole(c2_set)
    @test Order_check.Flags.sourCream(c2_set)
    end
    
    @testset "ASCII Character Arrays Inside Groups" begin
        # Test fixed-length ASCII character arrays in groups
        # Java: allowsEncodingAndDecodingAsciiInsideGroupInSchemaDefinedOrder
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.AsciiInsideGroup.Encoder(buffer)
        
        # Set top-level ASCII field (ccyPair is 6-char US-ASCII)
        Order_check.AsciiInsideGroup.a!(enc, "EURUSD")
        
        # Create group with ASCII fields
        b_enc = Order_check.AsciiInsideGroup.b!(enc, 2)
        
        Order_check.AsciiInsideGroup.B.next!(b_enc)
        Order_check.AsciiInsideGroup.B.c!(b_enc, "GBPUSD")
        
        Order_check.AsciiInsideGroup.B.next!(b_enc)
        Order_check.AsciiInsideGroup.B.c!(b_enc, "USDJPY")
        
        # Decode and verify
        dec = Order_check.AsciiInsideGroup.Decoder(buffer)
        @test Order_check.AsciiInsideGroup.a(dec) == "EURUSD"
        
    b_dec = Order_check.AsciiInsideGroup.b(dec)
    Order_check.AsciiInsideGroup.B.next!(b_dec)
    @test Order_check.AsciiInsideGroup.B.c(b_dec) == "GBPUSD"
    Order_check.AsciiInsideGroup.B.next!(b_dec)
    @test Order_check.AsciiInsideGroup.B.c(b_dec) == "USDJPY"
    end
    
    @testset "Empty Groups - Zero Count" begin
        # Test groups with count=0
        # Java: disallowsEncodingElementOfEmptyGroup (we allow but verify behavior)
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.NestedGroups.Encoder(buffer)
        
        Order_check.NestedGroups.a!(enc, 42)
        
        # Create empty outer group
        b_enc = Order_check.NestedGroups.b!(enc, 0)
        @test length(b_enc) == 0
        @test Base.isdone(b_enc)
        
        # Skip to next group h
        h_enc = Order_check.NestedGroups.h!(enc, 1)
        Order_check.NestedGroups.H.next!(h_enc)
        Order_check.NestedGroups.H.i!(h_enc, 99)
        
        # Decode and verify empty group
        dec = Order_check.NestedGroups.Decoder(buffer)
        @test Order_check.NestedGroups.a(dec) == 42
        
    b_dec = Order_check.NestedGroups.b(dec)
    @test length(b_dec) == 0
    # Verify we can still access h
    h_dec = Order_check.NestedGroups.h(dec)
    Order_check.NestedGroups.H.next!(h_dec)
    @test Order_check.NestedGroups.H.i(h_dec) == 99
    end
    
    @testset "Groups with No Block Fields" begin
        # Test groups that only contain vardata (no fixed fields)
        # Java: GroupWithNoBlock message tests
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.GroupWithNoBlock.Encoder(buffer)
        
        # Group with only vardata field
        a_enc = Order_check.GroupWithNoBlock.a!(enc, 2)
        
        Order_check.GroupWithNoBlock.A.next!(a_enc)
        Order_check.GroupWithNoBlock.A.b!(a_enc, "first")
        
        Order_check.GroupWithNoBlock.A.next!(a_enc)
        Order_check.GroupWithNoBlock.A.b!(a_enc, "second")
        
        # Decode and verify
        dec = Order_check.GroupWithNoBlock.Decoder(buffer)
    a_dec = Order_check.GroupWithNoBlock.a(dec)
    Order_check.GroupWithNoBlock.A.next!(a_dec)
    @test Order_check.GroupWithNoBlock.A.b(a_dec) == "first"
    Order_check.GroupWithNoBlock.A.next!(a_dec)
    @test Order_check.GroupWithNoBlock.A.b(a_dec) == "second"
    end
    
    @testset "Message with No Block Fields" begin
        # Test message that only contains vardata
        # Java: NoBlock message tests
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.NoBlock.Encoder(buffer)
        
        Order_check.NoBlock.a!(enc, "hello world")
        
        # Decode and verify
        dec = Order_check.NoBlock.Decoder(buffer)
        @test Order_check.NoBlock.a(dec) == "hello world"
    end
    
    @testset "Multiple VarData Fields" begin
        # Test message with multiple vardata fields
        # Java: MultipleVarLength tests
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.MultipleVarLength.Encoder(buffer)
        
        Order_check.MultipleVarLength.a!(enc, 42)
        Order_check.MultipleVarLength.b!(enc, "first variable")
        Order_check.MultipleVarLength.c!(enc, "second variable")
        
        # Decode and verify
    dec = Order_check.MultipleVarLength.Decoder(buffer)
    @test Order_check.MultipleVarLength.a(dec) == 42
    @test Order_check.MultipleVarLength.b(dec) == "first variable"
    @test Order_check.MultipleVarLength.c(dec) == "second variable"
    end
    
    @testset "Group and VarData Combination" begin
        # Test message with both group and vardata at top level
        # Java: GroupAndVarLength tests
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.GroupAndVarLength.Encoder(buffer)
        
        Order_check.GroupAndVarLength.a!(enc, 100)
        
        b_enc = Order_check.GroupAndVarLength.b!(enc, 2)
        Order_check.GroupAndVarLength.B.next!(b_enc)
        Order_check.GroupAndVarLength.B.c!(b_enc, 1)
        Order_check.GroupAndVarLength.B.next!(b_enc)
        Order_check.GroupAndVarLength.B.c!(b_enc, 2)
        
        Order_check.GroupAndVarLength.d!(enc, "variable data")
        
        # Decode and verify
        dec = Order_check.GroupAndVarLength.Decoder(buffer)
        @test Order_check.GroupAndVarLength.a(dec) == 100
        
    b_dec = Order_check.GroupAndVarLength.b(dec)
    Order_check.GroupAndVarLength.B.next!(b_dec)
    @test Order_check.GroupAndVarLength.B.c(b_dec) == 1
    Order_check.GroupAndVarLength.B.next!(b_dec)
    @test Order_check.GroupAndVarLength.B.c(b_dec) == 2
    @test Order_check.GroupAndVarLength.d(dec) == "variable data"
    end
    
    @testset "Multiple Groups at Top Level" begin
        # Test message with multiple groups at the same level
        # Java: MultipleGroups tests
        
        buffer = zeros(UInt8, 512)
        enc = Order_check.MultipleGroups.Encoder(buffer)
        
        Order_check.MultipleGroups.a!(enc, 42)
        
        # First group
        b_enc = Order_check.MultipleGroups.b!(enc, 2)
        Order_check.MultipleGroups.B.next!(b_enc)
        Order_check.MultipleGroups.B.c!(b_enc, 1)
        Order_check.MultipleGroups.B.next!(b_enc)
        Order_check.MultipleGroups.B.c!(b_enc, 2)
        
        # Second group
        d_enc = Order_check.MultipleGroups.d!(enc, 1)
        Order_check.MultipleGroups.D.next!(d_enc)
        Order_check.MultipleGroups.D.e!(d_enc, 99)
        
        # Decode and verify
        dec = Order_check.MultipleGroups.Decoder(buffer)
        @test Order_check.MultipleGroups.a(dec) == 42
        
    b_dec = Order_check.MultipleGroups.b(dec)
    Order_check.MultipleGroups.B.next!(b_dec)
    @test Order_check.MultipleGroups.B.c(b_dec) == 1
    Order_check.MultipleGroups.B.next!(b_dec)
    @test Order_check.MultipleGroups.B.c(b_dec) == 2
    d_dec = Order_check.MultipleGroups.d(dec)
    Order_check.MultipleGroups.D.next!(d_dec)
    @test Order_check.MultipleGroups.D.e(d_dec) == 99
    end
end
