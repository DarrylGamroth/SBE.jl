using Test
using SBE

@testset "Complex Group & VarData Patterns" begin
    # Use pre-generated OrderCheck module (loaded by runtests.jl)
    
    @testset "Nested Groups - 3 Levels Deep" begin
        # Test deeply nested group structure based on NestedGroups message
        # Schema: a -> b -> (d, f) where d and f are nested groups
        # Java: allowsEncodingNestedGroupsInSchemaDefinedOrder
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.NestedGroups.Encoder(typeof(buffer))
        OrderCheck.NestedGroups.wrap_and_apply_header!(enc, buffer, 0)
        
        # Set top-level field
        OrderCheck.NestedGroups.a!(enc, 42)
        
        # Create outer group b with 1 element
        b_enc = OrderCheck.NestedGroups.b!(enc, 1)
        OrderCheck.NestedGroups.B.next!(b_enc)
        OrderCheck.NestedGroups.B.c!(b_enc, 1)
        
        # Create nested group d within b (2 elements)
        d_enc = OrderCheck.NestedGroups.B.d!(b_enc, 2)
        OrderCheck.NestedGroups.B.D.next!(d_enc)
        OrderCheck.NestedGroups.B.D.e!(d_enc, 2)
        OrderCheck.NestedGroups.B.D.next!(d_enc)
        OrderCheck.NestedGroups.B.D.e!(d_enc, 3)
        
        # Create sibling nested group f within b (1 element)
        f_enc = OrderCheck.NestedGroups.B.f!(b_enc, 1)
        OrderCheck.NestedGroups.B.F.next!(f_enc)
        OrderCheck.NestedGroups.B.F.g!(f_enc, 4)
        
        # Create top-level group h (1 element)
        h_enc = OrderCheck.NestedGroups.h!(enc, 1)
        OrderCheck.NestedGroups.H.next!(h_enc)
        OrderCheck.NestedGroups.H.i!(h_enc, 5)
        
        # Decode and verify the nested structure
        dec = OrderCheck.NestedGroups.Decoder(typeof(buffer))
        OrderCheck.NestedGroups.wrap!(dec, buffer, 0)
        @test OrderCheck.NestedGroups.a(dec) == 42
        
        # Decode outer group b
    b_dec = OrderCheck.NestedGroups.b(dec)
    @test length(b_dec) == 1
    OrderCheck.NestedGroups.B.next!(b_dec)
    @test OrderCheck.NestedGroups.B.c(b_dec) == 1
    # Decode nested group d
    d_dec = OrderCheck.NestedGroups.B.d(b_dec)
    @test length(d_dec) == 2
    OrderCheck.NestedGroups.B.D.next!(d_dec)
    @test OrderCheck.NestedGroups.B.D.e(d_dec) == 2
    OrderCheck.NestedGroups.B.D.next!(d_dec)
    @test OrderCheck.NestedGroups.B.D.e(d_dec) == 3
    # Decode sibling nested group f
    f_dec = OrderCheck.NestedGroups.B.f(b_dec)
    @test length(f_dec) == 1
    OrderCheck.NestedGroups.B.F.next!(f_dec)
    @test OrderCheck.NestedGroups.B.F.g(f_dec) == 4
    # Decode top-level group h
    h_dec = OrderCheck.NestedGroups.h(dec)
    @test length(h_dec) == 1
    OrderCheck.NestedGroups.H.next!(h_dec)
    @test OrderCheck.NestedGroups.H.i(h_dec) == 5
    end
    
    @testset "VarData Inside Groups" begin
        # Test variable-length data within group elements
        # Java: allowsEncodingAndDecodingVariableLengthFieldInsideGroupInSchemaDefinedOrder
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.VarLengthInsideGroup.Encoder(typeof(buffer))
        OrderCheck.VarLengthInsideGroup.wrap_and_apply_header!(enc, buffer, 0)
        
        # Set top-level field
        OrderCheck.VarLengthInsideGroup.a!(enc, 100)
        
        # Create group with 2 elements, each containing vardata
        b_enc = OrderCheck.VarLengthInsideGroup.b!(enc, 2)
        
        # First element with vardata
        OrderCheck.VarLengthInsideGroup.B.next!(b_enc)
        OrderCheck.VarLengthInsideGroup.B.c!(b_enc, 1)
        OrderCheck.VarLengthInsideGroup.B.d!(b_enc, "abc")
        
        # Second element with vardata
        OrderCheck.VarLengthInsideGroup.B.next!(b_enc)
        OrderCheck.VarLengthInsideGroup.B.c!(b_enc, 2)
        OrderCheck.VarLengthInsideGroup.B.d!(b_enc, "defgh")
        
        # Top-level vardata
        OrderCheck.VarLengthInsideGroup.e!(enc, "xyz")
        
        # Decode and verify
        dec = OrderCheck.VarLengthInsideGroup.Decoder(typeof(buffer))
        OrderCheck.VarLengthInsideGroup.wrap!(dec, buffer, 0)
        @test OrderCheck.VarLengthInsideGroup.a(dec) == 100
        
    b_dec = OrderCheck.VarLengthInsideGroup.b(dec)
    @test length(b_dec) == 2
    OrderCheck.VarLengthInsideGroup.B.next!(b_dec)
    @test OrderCheck.VarLengthInsideGroup.B.c(b_dec) == 1
    @test OrderCheck.VarLengthInsideGroup.B.d(b_dec) == "abc"
    OrderCheck.VarLengthInsideGroup.B.next!(b_dec)
    @test OrderCheck.VarLengthInsideGroup.B.c(b_dec) == 2
    @test OrderCheck.VarLengthInsideGroup.B.d(b_dec) == "defgh"
    # Top-level vardata
    @test OrderCheck.VarLengthInsideGroup.e(dec) == "xyz"
    end
    
    @testset "VarData in Nested Groups" begin
        # Test vardata in deeply nested groups
        # Java: NestedGroupWithVarLength message tests
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.NestedGroupWithVarLength.Encoder(typeof(buffer))
        OrderCheck.NestedGroupWithVarLength.wrap_and_apply_header!(enc, buffer, 0)
        
        OrderCheck.NestedGroupWithVarLength.a!(enc, 42)
        
        # Outer group
        b_enc = OrderCheck.NestedGroupWithVarLength.b!(enc, 1)
        OrderCheck.NestedGroupWithVarLength.B.next!(b_enc)
        OrderCheck.NestedGroupWithVarLength.B.c!(b_enc, 100)
        
        # Nested group with vardata
        d_enc = OrderCheck.NestedGroupWithVarLength.B.d!(b_enc, 2)
        
        OrderCheck.NestedGroupWithVarLength.B.D.next!(d_enc)
        OrderCheck.NestedGroupWithVarLength.B.D.e!(d_enc, 1)
        OrderCheck.NestedGroupWithVarLength.B.D.f!(d_enc, "first")
        
        OrderCheck.NestedGroupWithVarLength.B.D.next!(d_enc)
        OrderCheck.NestedGroupWithVarLength.B.D.e!(d_enc, 2)
        OrderCheck.NestedGroupWithVarLength.B.D.f!(d_enc, "second")
        
        # Decode and verify
        dec = OrderCheck.NestedGroupWithVarLength.Decoder(typeof(buffer))
        OrderCheck.NestedGroupWithVarLength.wrap!(dec, buffer, 0)
        @test OrderCheck.NestedGroupWithVarLength.a(dec) == 42
        
    b_dec = OrderCheck.NestedGroupWithVarLength.b(dec)
    OrderCheck.NestedGroupWithVarLength.B.next!(b_dec)
    @test OrderCheck.NestedGroupWithVarLength.B.c(b_dec) == 100
    d_dec = OrderCheck.NestedGroupWithVarLength.B.d(b_dec)
    OrderCheck.NestedGroupWithVarLength.B.D.next!(d_dec)
    @test OrderCheck.NestedGroupWithVarLength.B.D.e(d_dec) == 1
    @test OrderCheck.NestedGroupWithVarLength.B.D.f(d_dec) == "first"
    OrderCheck.NestedGroupWithVarLength.B.D.next!(d_dec)
    @test OrderCheck.NestedGroupWithVarLength.B.D.e(d_dec) == 2
    @test OrderCheck.NestedGroupWithVarLength.B.D.f(d_dec) == "second"
    end
    
    @testset "Arrays Inside Groups" begin
        # Test fixed-size arrays within group elements
        # Java: allowsEncodingAndDecodingArrayInsideGroup
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.ArrayInsideGroup.Encoder(typeof(buffer))
        OrderCheck.ArrayInsideGroup.wrap_and_apply_header!(enc, buffer, 0)
        
        # Set top-level array field (ipV4Address is 4-byte array)
        OrderCheck.ArrayInsideGroup.a!(enc, UInt8[192, 168, 1, 1])
        
        # Create group with array fields
        b_enc = OrderCheck.ArrayInsideGroup.b!(enc, 2)
        
        OrderCheck.ArrayInsideGroup.B.next!(b_enc)
        OrderCheck.ArrayInsideGroup.B.c!(b_enc, UInt8[10, 0, 0, 1])
        
        OrderCheck.ArrayInsideGroup.B.next!(b_enc)
        OrderCheck.ArrayInsideGroup.B.c!(b_enc, UInt8[10, 0, 0, 2])
        
        # Decode and verify
        dec = OrderCheck.ArrayInsideGroup.Decoder(typeof(buffer))
        OrderCheck.ArrayInsideGroup.wrap!(dec, buffer, 0)
        a_val = OrderCheck.ArrayInsideGroup.a(dec)
        @test a_val == UInt8[192, 168, 1, 1]
        
    b_dec = OrderCheck.ArrayInsideGroup.b(dec)
    OrderCheck.ArrayInsideGroup.B.next!(b_dec)
    @test OrderCheck.ArrayInsideGroup.B.c(b_dec) == UInt8[10, 0, 0, 1]
    OrderCheck.ArrayInsideGroup.B.next!(b_dec)
    @test OrderCheck.ArrayInsideGroup.B.c(b_dec) == UInt8[10, 0, 0, 2]
    end
    
    @testset "Composites Inside Groups" begin
        # Test composite types within group elements
        # Java: allowsEncodingAndDecodingCompositeInsideGroupInSchemaDefinedOrder
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.CompositeInsideGroup.Encoder(typeof(buffer))
        OrderCheck.CompositeInsideGroup.wrap_and_apply_header!(enc, buffer, 0)
        
        # Set top-level composite field (point has x, y)
        a_comp = OrderCheck.CompositeInsideGroup.a(enc)
        OrderCheck.Point.x!(a_comp, 10)
        OrderCheck.Point.y!(a_comp, 20)
        
        # Create group with composite fields
        b_enc = OrderCheck.CompositeInsideGroup.b!(enc, 2)
        
        OrderCheck.CompositeInsideGroup.B.next!(b_enc)
        c1_comp = OrderCheck.CompositeInsideGroup.B.c(b_enc)
        OrderCheck.Point.x!(c1_comp, 100)
        OrderCheck.Point.y!(c1_comp, 200)
        
        OrderCheck.CompositeInsideGroup.B.next!(b_enc)
        c2_comp = OrderCheck.CompositeInsideGroup.B.c(b_enc)
        OrderCheck.Point.x!(c2_comp, 300)
        OrderCheck.Point.y!(c2_comp, 400)
        
        # Decode and verify
        dec = OrderCheck.CompositeInsideGroup.Decoder(typeof(buffer))
        OrderCheck.CompositeInsideGroup.wrap!(dec, buffer, 0)
        a_val = OrderCheck.CompositeInsideGroup.a(dec)
        @test OrderCheck.Point.x(a_val) == 10
        @test OrderCheck.Point.y(a_val) == 20
        
    b_dec = OrderCheck.CompositeInsideGroup.b(dec)
    OrderCheck.CompositeInsideGroup.B.next!(b_dec)
    c1 = OrderCheck.CompositeInsideGroup.B.c(b_dec)
    @test OrderCheck.Point.x(c1) == 100
    @test OrderCheck.Point.y(c1) == 200
    OrderCheck.CompositeInsideGroup.B.next!(b_dec)
    c2 = OrderCheck.CompositeInsideGroup.B.c(b_dec)
    @test OrderCheck.Point.x(c2) == 300
    @test OrderCheck.Point.y(c2) == 400
    end
    
    @testset "Enums Inside Groups" begin
        # Test enum types within group elements
        # Java: EnumInsideGroup tests
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.EnumInsideGroup.Encoder(typeof(buffer))
        OrderCheck.EnumInsideGroup.wrap_and_apply_header!(enc, buffer, 0)
        
        # Set top-level enum
        OrderCheck.EnumInsideGroup.a!(enc, OrderCheck.Direction.BUY)
        
        # Create group with enum fields
        b_enc = OrderCheck.EnumInsideGroup.b!(enc, 2)
        
        OrderCheck.EnumInsideGroup.B.next!(b_enc)
        OrderCheck.EnumInsideGroup.B.c!(b_enc, OrderCheck.Direction.BUY)
        
        OrderCheck.EnumInsideGroup.B.next!(b_enc)
        OrderCheck.EnumInsideGroup.B.c!(b_enc, OrderCheck.Direction.SELL)
        
        # Decode and verify
        dec = OrderCheck.EnumInsideGroup.Decoder(typeof(buffer))
        OrderCheck.EnumInsideGroup.wrap!(dec, buffer, 0)
        @test OrderCheck.EnumInsideGroup.a(dec) == OrderCheck.Direction.BUY
        
    b_dec = OrderCheck.EnumInsideGroup.b(dec)
    OrderCheck.EnumInsideGroup.B.next!(b_dec)
    @test OrderCheck.EnumInsideGroup.B.c(b_dec) == OrderCheck.Direction.BUY
    OrderCheck.EnumInsideGroup.B.next!(b_dec)
    @test OrderCheck.EnumInsideGroup.B.c(b_dec) == OrderCheck.Direction.SELL
    end
    
    @testset "BitSets Inside Groups" begin
        # Test bitset types within group elements
        # Java: BitSetInsideGroup tests
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.BitSetInsideGroup.Encoder(typeof(buffer))
        OrderCheck.BitSetInsideGroup.wrap_and_apply_header!(enc, buffer, 0)
        
        # Set top-level bitset (correct pattern: get set accessor, then set individual bits)
        a_set_enc = OrderCheck.BitSetInsideGroup.a(enc)
        OrderCheck.Flags.guacamole!(a_set_enc, true)
        
        # Create group with bitset fields
        b_enc = OrderCheck.BitSetInsideGroup.b!(enc, 2)
        
        OrderCheck.BitSetInsideGroup.B.next!(b_enc)
        c1_set_enc = OrderCheck.BitSetInsideGroup.B.c(b_enc)
        OrderCheck.Flags.cheese!(c1_set_enc, true)
        
        OrderCheck.BitSetInsideGroup.B.next!(b_enc)
        c2_set_enc = OrderCheck.BitSetInsideGroup.B.c(b_enc)
        OrderCheck.Flags.guacamole!(c2_set_enc, true)
        OrderCheck.Flags.sourCream!(c2_set_enc, true)
        
        # Decode and verify
        dec = OrderCheck.BitSetInsideGroup.Decoder(typeof(buffer))
        OrderCheck.BitSetInsideGroup.wrap!(dec, buffer, 0)
        a_set = OrderCheck.BitSetInsideGroup.a(dec)
        @test OrderCheck.Flags.guacamole(a_set)
        @test !OrderCheck.Flags.cheese(a_set)
        
    b_dec = OrderCheck.BitSetInsideGroup.b(dec)
    OrderCheck.BitSetInsideGroup.B.next!(b_dec)
    c1_set = OrderCheck.BitSetInsideGroup.B.c(b_dec)
    @test OrderCheck.Flags.cheese(c1_set)
    OrderCheck.BitSetInsideGroup.B.next!(b_dec)
    c2_set = OrderCheck.BitSetInsideGroup.B.c(b_dec)
    @test OrderCheck.Flags.guacamole(c2_set)
    @test OrderCheck.Flags.sourCream(c2_set)
    end
    
    @testset "ASCII Character Arrays Inside Groups" begin
        # Test fixed-length ASCII character arrays in groups
        # Java: allowsEncodingAndDecodingAsciiInsideGroupInSchemaDefinedOrder
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.AsciiInsideGroup.Encoder(typeof(buffer))
        OrderCheck.AsciiInsideGroup.wrap_and_apply_header!(enc, buffer, 0)
        
        # Set top-level ASCII field (ccyPair is 6-char US-ASCII)
        OrderCheck.AsciiInsideGroup.a!(enc, "EURUSD")
        
        # Create group with ASCII fields
        b_enc = OrderCheck.AsciiInsideGroup.b!(enc, 2)
        
        OrderCheck.AsciiInsideGroup.B.next!(b_enc)
        OrderCheck.AsciiInsideGroup.B.c!(b_enc, "GBPUSD")
        
        OrderCheck.AsciiInsideGroup.B.next!(b_enc)
        OrderCheck.AsciiInsideGroup.B.c!(b_enc, "USDJPY")
        
        # Decode and verify
        dec = OrderCheck.AsciiInsideGroup.Decoder(typeof(buffer))
        OrderCheck.AsciiInsideGroup.wrap!(dec, buffer, 0)
        @test OrderCheck.AsciiInsideGroup.a(dec) == "EURUSD"
        
    b_dec = OrderCheck.AsciiInsideGroup.b(dec)
    OrderCheck.AsciiInsideGroup.B.next!(b_dec)
    @test OrderCheck.AsciiInsideGroup.B.c(b_dec) == "GBPUSD"
    OrderCheck.AsciiInsideGroup.B.next!(b_dec)
    @test OrderCheck.AsciiInsideGroup.B.c(b_dec) == "USDJPY"
    end
    
    @testset "Empty Groups - Zero Count" begin
        # Test groups with count=0
        # Java: disallowsEncodingElementOfEmptyGroup (we allow but verify behavior)
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.NestedGroups.Encoder(typeof(buffer))
        OrderCheck.NestedGroups.wrap_and_apply_header!(enc, buffer, 0)
        
        OrderCheck.NestedGroups.a!(enc, 42)
        
        # Create empty outer group
        b_enc = OrderCheck.NestedGroups.b!(enc, 0)
        @test length(b_enc) == 0
        @test Base.isdone(b_enc)
        
        # Skip to next group h
        h_enc = OrderCheck.NestedGroups.h!(enc, 1)
        OrderCheck.NestedGroups.H.next!(h_enc)
        OrderCheck.NestedGroups.H.i!(h_enc, 99)
        
        # Decode and verify empty group
        dec = OrderCheck.NestedGroups.Decoder(typeof(buffer))
        OrderCheck.NestedGroups.wrap!(dec, buffer, 0)
        @test OrderCheck.NestedGroups.a(dec) == 42
        
    b_dec = OrderCheck.NestedGroups.b(dec)
    @test length(b_dec) == 0
    # Verify we can still access h
    h_dec = OrderCheck.NestedGroups.h(dec)
    OrderCheck.NestedGroups.H.next!(h_dec)
    @test OrderCheck.NestedGroups.H.i(h_dec) == 99
    end
    
    @testset "Groups with No Block Fields" begin
        # Test groups that only contain vardata (no fixed fields)
        # Java: GroupWithNoBlock message tests
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.GroupWithNoBlock.Encoder(typeof(buffer))
        OrderCheck.GroupWithNoBlock.wrap_and_apply_header!(enc, buffer, 0)
        
        # Group with only vardata field
        a_enc = OrderCheck.GroupWithNoBlock.a!(enc, 2)
        
        OrderCheck.GroupWithNoBlock.A.next!(a_enc)
        OrderCheck.GroupWithNoBlock.A.b!(a_enc, "first")
        
        OrderCheck.GroupWithNoBlock.A.next!(a_enc)
        OrderCheck.GroupWithNoBlock.A.b!(a_enc, "second")
        
        # Decode and verify
        dec = OrderCheck.GroupWithNoBlock.Decoder(typeof(buffer))
        OrderCheck.GroupWithNoBlock.wrap!(dec, buffer, 0)
    a_dec = OrderCheck.GroupWithNoBlock.a(dec)
    OrderCheck.GroupWithNoBlock.A.next!(a_dec)
    @test OrderCheck.GroupWithNoBlock.A.b(a_dec) == "first"
    OrderCheck.GroupWithNoBlock.A.next!(a_dec)
    @test OrderCheck.GroupWithNoBlock.A.b(a_dec) == "second"
    end
    
    @testset "Message with No Block Fields" begin
        # Test message that only contains vardata
        # Java: NoBlock message tests
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.NoBlock.Encoder(typeof(buffer))
        OrderCheck.NoBlock.wrap_and_apply_header!(enc, buffer, 0)
        
        OrderCheck.NoBlock.a!(enc, "hello world")
        
        # Decode and verify
        dec = OrderCheck.NoBlock.Decoder(typeof(buffer))
        OrderCheck.NoBlock.wrap!(dec, buffer, 0)
        @test OrderCheck.NoBlock.a(dec) == "hello world"
    end
    
    @testset "Multiple VarData Fields" begin
        # Test message with multiple vardata fields
        # Java: MultipleVarLength tests
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.MultipleVarLength.Encoder(typeof(buffer))
        OrderCheck.MultipleVarLength.wrap_and_apply_header!(enc, buffer, 0)
        
        OrderCheck.MultipleVarLength.a!(enc, 42)
        OrderCheck.MultipleVarLength.b!(enc, "first variable")
        OrderCheck.MultipleVarLength.c!(enc, "second variable")
        
        # Decode and verify
    dec = OrderCheck.MultipleVarLength.Decoder(typeof(buffer))
    OrderCheck.MultipleVarLength.wrap!(dec, buffer, 0)
    @test OrderCheck.MultipleVarLength.a(dec) == 42
    @test OrderCheck.MultipleVarLength.b(dec) == "first variable"
    @test OrderCheck.MultipleVarLength.c(dec) == "second variable"
    end
    
    @testset "Group and VarData Combination" begin
        # Test message with both group and vardata at top level
        # Java: GroupAndVarLength tests
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.GroupAndVarLength.Encoder(typeof(buffer))
        OrderCheck.GroupAndVarLength.wrap_and_apply_header!(enc, buffer, 0)
        
        OrderCheck.GroupAndVarLength.a!(enc, 100)
        
        b_enc = OrderCheck.GroupAndVarLength.b!(enc, 2)
        OrderCheck.GroupAndVarLength.B.next!(b_enc)
        OrderCheck.GroupAndVarLength.B.c!(b_enc, 1)
        OrderCheck.GroupAndVarLength.B.next!(b_enc)
        OrderCheck.GroupAndVarLength.B.c!(b_enc, 2)
        
        OrderCheck.GroupAndVarLength.d!(enc, "variable data")
        
        # Decode and verify
        dec = OrderCheck.GroupAndVarLength.Decoder(typeof(buffer))
        OrderCheck.GroupAndVarLength.wrap!(dec, buffer, 0)
        @test OrderCheck.GroupAndVarLength.a(dec) == 100
        
    b_dec = OrderCheck.GroupAndVarLength.b(dec)
    OrderCheck.GroupAndVarLength.B.next!(b_dec)
    @test OrderCheck.GroupAndVarLength.B.c(b_dec) == 1
    OrderCheck.GroupAndVarLength.B.next!(b_dec)
    @test OrderCheck.GroupAndVarLength.B.c(b_dec) == 2
    @test OrderCheck.GroupAndVarLength.d(dec) == "variable data"
    end
    
    @testset "Multiple Groups at Top Level" begin
        # Test message with multiple groups at the same level
        # Java: MultipleGroups tests
        
        buffer = zeros(UInt8, 512)
        enc = OrderCheck.MultipleGroups.Encoder(typeof(buffer))
        OrderCheck.MultipleGroups.wrap_and_apply_header!(enc, buffer, 0)
        
        OrderCheck.MultipleGroups.a!(enc, 42)
        
        # First group
        b_enc = OrderCheck.MultipleGroups.b!(enc, 2)
        OrderCheck.MultipleGroups.B.next!(b_enc)
        OrderCheck.MultipleGroups.B.c!(b_enc, 1)
        OrderCheck.MultipleGroups.B.next!(b_enc)
        OrderCheck.MultipleGroups.B.c!(b_enc, 2)
        
        # Second group
        d_enc = OrderCheck.MultipleGroups.d!(enc, 1)
        OrderCheck.MultipleGroups.D.next!(d_enc)
        OrderCheck.MultipleGroups.D.e!(d_enc, 99)
        
        # Decode and verify
        dec = OrderCheck.MultipleGroups.Decoder(typeof(buffer))
        OrderCheck.MultipleGroups.wrap!(dec, buffer, 0)
        @test OrderCheck.MultipleGroups.a(dec) == 42
        
    b_dec = OrderCheck.MultipleGroups.b(dec)
    OrderCheck.MultipleGroups.B.next!(b_dec)
    @test OrderCheck.MultipleGroups.B.c(b_dec) == 1
    OrderCheck.MultipleGroups.B.next!(b_dec)
    @test OrderCheck.MultipleGroups.B.c(b_dec) == 2
    d_dec = OrderCheck.MultipleGroups.d(dec)
    OrderCheck.MultipleGroups.D.next!(d_dec)
    @test OrderCheck.MultipleGroups.D.e(d_dec) == 99
    end
end
