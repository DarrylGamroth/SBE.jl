using Test
using SBE

@testset "Version Handling for All Field Types" begin
    # Use pre-generated Versioned module (loaded by runtests.jl)
    
    buffer = zeros(UInt8, 4096)
    
    @testset "Schema Metadata" begin
        # Verify schema loaded correctly
        @test isdefined(Versioned, :Product)
        @test isdefined(Versioned, :Status)
        @test isdefined(Versioned, :Features)
    end
    
    @testset "Enum Version Handling" begin
        # Version 0: status field should return null value
        position_ptr_v0 = SBE.PositionPointer()
        product_v0 = Versioned.Product.Decoder(typeof(buffer))
        product_v0.position_ptr = position_ptr_v0
        Versioned.Product.wrap!(product_v0, buffer, 0, UInt16(16), UInt16(0))
        
        # Status field is in version 1, so should return null for version 0
        status_v0 = Versioned.Product.status(product_v0)
        @test status_v0 isa Versioned.Status.SbeEnum
        
        # Version 1: status field should be accessible
        position_ptr_v1 = SBE.PositionPointer()
        product_v1 = Versioned.Product.Decoder(typeof(buffer))
        product_v1.position_ptr = position_ptr_v1
        Versioned.Product.wrap!(product_v1, buffer, 0, UInt16(17), UInt16(1))
        status_v1 = Versioned.Product.status(product_v1)
        @test status_v1 isa Versioned.Status.SbeEnum
    end
    
    @testset "Set Version Handling" begin
        # Version 1: features field should return empty set
        position_ptr_v1 = SBE.PositionPointer()
        product_v1 = Versioned.Product.Decoder(typeof(buffer))
        product_v1.position_ptr = position_ptr_v1
        Versioned.Product.wrap!(product_v1, buffer, 0, UInt16(17), UInt16(1))
        
        features_v1 = Versioned.Product.features(product_v1)
        @test features_v1 isa Versioned.Features.Decoder
        
        # Version 2: features field should be accessible
        position_ptr_v2 = SBE.PositionPointer()
        product_v2 = Versioned.Product.Decoder(typeof(buffer))
        product_v2.position_ptr = position_ptr_v2
        Versioned.Product.wrap!(product_v2, buffer, 0, UInt16(19), UInt16(2))
        features_v2 = Versioned.Product.features(product_v2)
        @test features_v2 isa Versioned.Features.Decoder
    end
    
    @testset "Group Version Handling" begin
        # Version 0: tags group should be empty
        position_ptr_v0 = SBE.PositionPointer()
        product_v0 = Versioned.Product.Decoder(typeof(buffer))
        product_v0.position_ptr = position_ptr_v0
        Versioned.Product.wrap!(product_v0, buffer, 0, UInt16(16), UInt16(0))
        
        tags_v0 = Versioned.Product.tags(product_v0)
        @test length(tags_v0) == 0  # Empty group when not in version
    end
    
    @testset "VarData Version Handling" begin
        # Version 1: description field should return empty view
        position_ptr_v1 = SBE.PositionPointer()
        product_v1 = Versioned.Product.Decoder(typeof(buffer))
        product_v1.position_ptr = position_ptr_v1
        Versioned.Product.wrap!(product_v1, buffer, 0, UInt16(17), UInt16(1))
        
        # description is version 2, so with version 1 decoder it should have 0 length
        desc_length = Versioned.Product.description_length(product_v1)
        @test desc_length == 0
        
        # Version 2: description field should be accessible
        position_ptr_v2 = SBE.PositionPointer()
        product_v2 = Versioned.Product.Decoder(typeof(buffer))
        product_v2.position_ptr = position_ptr_v2
        Versioned.Product.wrap!(product_v2, buffer, 0, UInt16(19), UInt16(2))
        
        # Should be able to get description length (though buffer is empty, it won't crash)
        desc_length_v2 = Versioned.Product.description_length(product_v2)
        @test desc_length_v2 isa UInt32  # Just verify it returns the right type
    end
    
    @testset "Metadata Constants" begin
        # Verify since_version constants exist
        @test Versioned.Product.status_since_version(Versioned.Product.Decoder) == UInt16(1)
        @test Versioned.Product.features_since_version(Versioned.Product.Decoder) == UInt16(2)
        @test Versioned.Product.priority_since_version(Versioned.Product.Decoder) == UInt16(1)
    end
end
