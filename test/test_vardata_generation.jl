using Test
using SBE

@testset "Variable Data Field Generation Tests" begin
    # Load schema to trigger variable data field generation
    schema_path = joinpath(@__DIR__, "example-schema.xml")
    baseline_module = load_schema(schema_path)
    
    @testset "Variable Data Field Types Created" begin
        # Test that variable data field types were generated
        @test isdefined(baseline_module, :ManufacturerField)
        @test isdefined(baseline_module, :ModelField)  
        @test isdefined(baseline_module, :ActivationCodeField)
        
        # Get the generated field types
        ManufacturerField = getfield(baseline_module, :ManufacturerField)
        ModelField = getfield(baseline_module, :ModelField)
        ActivationCodeField = getfield(baseline_module, :ActivationCodeField)
        
        # Test field types are proper types
        @test ManufacturerField isa Type
        @test ModelField isa Type
        @test ActivationCodeField isa Type
        
        # Test field types have the right structure (should take buffer, offset, position_ptr)
        @test fieldnames(ManufacturerField) == (:buffer, :offset, :position_ptr)
        @test fieldnames(ModelField) == (:buffer, :offset, :position_ptr)
        @test fieldnames(ActivationCodeField) == (:buffer, :offset, :position_ptr)
    end
    
    @testset "Variable Data Field Interface" begin
        # Create a test buffer
        buffer = zeros(UInt8, 1024)
        position_ptr = Ref(Int64(100))
        
        # Create field instances
        ManufacturerField = getfield(baseline_module, :ManufacturerField)
        manufacturer_field = ManufacturerField(buffer, 50, position_ptr)
        
        # Test SBE interface methods exist
        @test hasmethod(SBE.id, (typeof(manufacturer_field),))
        @test hasmethod(SBE.since_version, (typeof(manufacturer_field),))
        
        # Test id and since_version work
        @test SBE.id(manufacturer_field) isa UInt16
        @test SBE.since_version(manufacturer_field) isa UInt16
        @test SBE.id(manufacturer_field) == UInt16(18)  # manufacturer field id
        
        # Test header_length method exists (should be defined in baseline module)
        @test hasmethod(baseline_module.header_length, (typeof(manufacturer_field),))
        @test baseline_module.header_length(manufacturer_field) > 0  # Should have some header length
    end
    
    @testset "Variable Data Field Values" begin
        # Create a test buffer with some space
        buffer = zeros(UInt8, 1024)
        position_ptr = Ref(Int64(100))
        
        # Create field instance
        ManufacturerField = getfield(baseline_module, :ManufacturerField)
        manufacturer_field = ManufacturerField(buffer, 50, position_ptr)
        
        # Test length methods exist (should be defined in baseline module)
        @test hasmethod(Base.length, (typeof(manufacturer_field),))
        
        # Test that the functions exist in the baseline module
        @test isdefined(baseline_module, :length!)
        @test isdefined(baseline_module, :skip!)
        
        # Test value methods exist  
        @test hasmethod(SBE.value, (typeof(manufacturer_field),))
        @test hasmethod(SBE.value!, (typeof(manufacturer_field), AbstractString))
        @test hasmethod(SBE.value!, (typeof(manufacturer_field), AbstractVector{UInt8}))
    end
end
