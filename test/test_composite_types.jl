using Test
using SBE
using SBE.Schema

@testset "Composite Type Generation" begin
    @testset "MessageHeader Composite Type" begin
        # Create a simple schema with MessageHeader composite type
        message_header_composite = Schema.CompositeType(
            "messageHeader",
            [
                Schema.EncodedType(
                    "blockLength", "uint16", 1, nothing, nothing, nothing, nothing, nothing,
                    "required", nothing, "", 0, nothing
                ),
                Schema.EncodedType(
                    "templateId", "uint16", 1, nothing, nothing, nothing, nothing, nothing,
                    "required", nothing, "", 0, nothing
                ),
                Schema.EncodedType(
                    "schemaId", "uint16", 1, nothing, nothing, nothing, nothing, nothing,
                    "required", nothing, "", 0, nothing
                ),
                Schema.EncodedType(
                    "version", "uint16", 1, nothing, nothing, nothing, nothing, nothing,
                    "required", nothing, "", 0, nothing
                )
            ],
            nothing, nothing, "Message identifiers and length of message root.", 0, nothing
        )
        
        schema = Schema.MessageSchema(
            UInt16(1), UInt16(0), "5.2", "test", "littleEndian", "messageHeader",
            "Test schema for composite types",
            [message_header_composite],
            Schema.MessageDefinition[]
        )
        
        # Create a test module for generating the composite type
        test_module_name = Symbol("TestCompositeModule")
        Core.eval(Main, :(module $test_module_name end))
        test_module = getfield(Main, test_module_name)
        
        # Import necessary dependencies into the test module
        Core.eval(test_module, :(using SBE: AbstractSbeCompositeType))
        Core.eval(test_module, :(using MappedArrays: mappedarray))
        Core.eval(test_module, :(import SBE: ltoh, htol))
        
        # Add utility functions
        Core.eval(test_module, quote
            @inline function encode_le(::Type{T}, buffer, offset, value) where {T}
                @inbounds reinterpret(T, view(buffer, offset+1:offset+sizeof(T)))[] = htol(value)
            end
            
            @inline function decode_le(::Type{T}, buffer, offset) where {T}
                @inbounds ltoh(reinterpret(T, view(buffer, offset+1:offset+sizeof(T)))[])
            end
        end)
        
        # Generate the MessageHeader composite type
        result = SBE.generate_complete_composite_type!(test_module, message_header_composite, schema)
        
        @test result == :MessageHeader
        @test isdefined(test_module, :MessageHeader)  # The module
        @test isdefined(test_module, :AbstractMessageHeader)
        @test isdefined(test_module, :MessageHeaderDecoder)
        @test isdefined(test_module, :MessageHeaderEncoder)
        
        # Test type hierarchy - access through the module
        MessageHeader = getfield(test_module, :MessageHeader)  # The module
        AbstractMessageHeader = getfield(MessageHeader, :AbstractMessageHeader)
        MessageHeaderDecoder = getfield(MessageHeader, :MessageHeaderDecoder)
        MessageHeaderEncoder = getfield(MessageHeader, :MessageHeaderEncoder)
        
        @test MessageHeaderDecoder <: AbstractMessageHeader
        @test MessageHeaderEncoder <: AbstractMessageHeader
        @test AbstractMessageHeader <: SBE.AbstractSbeCompositeType
        
        # Test basic instantiation
        buffer = zeros(UInt8, 16)
        header_decoder = MessageHeaderDecoder(buffer, 0, 0)
        header_encoder = MessageHeaderEncoder(buffer, 0, 0)
        
        @test typeof(header_decoder) <: MessageHeaderDecoder
        @test typeof(header_encoder) <: MessageHeaderEncoder
        
        # Test SBE interface methods - access through the module
        sbe_buffer = getfield(MessageHeader, :sbe_buffer)
        sbe_offset = getfield(MessageHeader, :sbe_offset)
        sbe_acting_version = getfield(MessageHeader, :sbe_acting_version)
        sbe_encoded_length = getfield(MessageHeader, :sbe_encoded_length)
        
        @test sbe_buffer(header_decoder) === buffer
        @test sbe_offset(header_decoder) == 0
        @test sbe_acting_version(header_decoder) == 0
        @test sbe_encoded_length(header_decoder) == 8  # 4 * UInt16
        @test sizeof(header_decoder) == 8
        
        # Test field accessors exist - access through the module
        @test isdefined(MessageHeader, :blockLength)
        @test isdefined(MessageHeader, :templateId)
        @test isdefined(MessageHeader, :schemaId)
        @test isdefined(MessageHeader, :version)
        
        # Test field setters exist for encoder
        @test isdefined(MessageHeader, Symbol("blockLength!"))
        @test isdefined(MessageHeader, Symbol("templateId!"))
        @test isdefined(MessageHeader, Symbol("schemaId!"))
        @test isdefined(MessageHeader, Symbol("version!"))
        
        # Test field type structs exist (in the MessageHeader module)
        @test isdefined(MessageHeader, :BlockLength)
        @test isdefined(MessageHeader, :TemplateId)
        @test isdefined(MessageHeader, :SchemaId)
        @test isdefined(MessageHeader, :Version)
        
        # Test field types have the dispatch interface methods
        BlockLength = getfield(MessageHeader, :BlockLength)
        TemplateId = getfield(MessageHeader, :TemplateId)  
        SchemaId = getfield(MessageHeader, :SchemaId)
        Version = getfield(MessageHeader, :Version)
        
        # Test encoding_offset dispatch method works (import needed in composite module)
        @test MessageHeader.encoding_offset(BlockLength) == 0
        @test MessageHeader.encoding_offset(TemplateId) == 2
        @test MessageHeader.encoding_offset(SchemaId) == 4
        @test MessageHeader.encoding_offset(Version) == 6
    end
    
    @testset "MessageHeader Field Access" begin
        # Create the same test setup
        message_header_composite = Schema.CompositeType(
            "messageHeader",
            [
                Schema.EncodedType(
                    "blockLength", "uint16", 1, nothing, nothing, nothing, nothing, nothing,
                    "required", nothing, "", 0, nothing
                ),
                Schema.EncodedType(
                    "templateId", "uint16", 1, nothing, nothing, nothing, nothing, nothing,
                    "required", nothing, "", 0, nothing
                ),
                Schema.EncodedType(
                    "schemaId", "uint16", 1, nothing, nothing, nothing, nothing, nothing,
                    "required", nothing, "", 0, nothing
                ),
                Schema.EncodedType(
                    "version", "uint16", 1, nothing, nothing, nothing, nothing, nothing,
                    "required", nothing, "", 0, nothing
                )
            ],
            nothing, nothing, "Message identifiers and length of message root.", 0, nothing
        )
        
        schema = Schema.MessageSchema(
            UInt16(1), UInt16(0), "5.2", "test", "littleEndian", "messageHeader",
            "Test schema for composite types",
            [message_header_composite],
            Schema.MessageDefinition[]
        )
        
        # Create a fresh test module
        test_module_name = Symbol("TestCompositeFieldModule")
        Core.eval(Main, :(module $test_module_name end))
        test_module = getfield(Main, test_module_name)
        
        # Import necessary dependencies
        Core.eval(test_module, :(using SBE: AbstractSbeCompositeType))
        Core.eval(test_module, :(using MappedArrays: mappedarray))
        Core.eval(test_module, :(import SBE: ltoh, htol))
        
        # Add utility functions
        Core.eval(test_module, quote
            @inline function encode_le(::Type{T}, buffer, offset, value) where {T}
                @inbounds reinterpret(T, view(buffer, offset+1:offset+sizeof(T)))[] = htol(value)
            end
            
            @inline function decode_le(::Type{T}, buffer, offset) where {T}
                @inbounds ltoh(reinterpret(T, view(buffer, offset+1:offset+sizeof(T)))[])
            end
        end)
        
        # Generate the composite type
        SBE.generate_complete_composite_type!(test_module, message_header_composite, schema)
        
        # Get the generated types and functions - access through the module
        MessageHeader = getfield(test_module, :MessageHeader)  # The module
        MessageHeaderDecoder = getfield(MessageHeader, :MessageHeaderDecoder)
        MessageHeaderEncoder = getfield(MessageHeader, :MessageHeaderEncoder)
        
        blockLength = getfield(MessageHeader, :blockLength)
        blockLength! = getfield(MessageHeader, Symbol("blockLength!"))
        templateId = getfield(MessageHeader, :templateId)
        templateId! = getfield(MessageHeader, Symbol("templateId!"))
        schemaId = getfield(MessageHeader, :schemaId)
        schemaId! = getfield(MessageHeader, Symbol("schemaId!"))
        version = getfield(MessageHeader, :version)
        version! = getfield(MessageHeader, Symbol("version!"))
        
        # Test reading and writing values
        buffer = zeros(UInt8, 16)
        encoder = MessageHeaderEncoder(buffer, 0, 0)
        decoder = MessageHeaderDecoder(buffer, 0, 0)
        
        # Write some values
        blockLength!(encoder, UInt16(42))
        templateId!(encoder, UInt16(100))
        schemaId!(encoder, UInt16(1))
        version!(encoder, UInt16(5))
        
        # Read them back
        @test blockLength(decoder) == UInt16(42)
        @test templateId(decoder) == UInt16(100)
        @test schemaId(decoder) == UInt16(1)
        @test version(decoder) == UInt16(5)
        
        # Test that values are stored in correct byte positions
        expected_buffer = zeros(UInt8, 16)
        # blockLength at offset 0
        reinterpret(UInt16, view(expected_buffer, 1:2))[] = htol(UInt16(42))
        # templateId at offset 2
        reinterpret(UInt16, view(expected_buffer, 3:4))[] = htol(UInt16(100))
        # schemaId at offset 4
        reinterpret(UInt16, view(expected_buffer, 5:6))[] = htol(UInt16(1))
        # version at offset 6
        reinterpret(UInt16, view(expected_buffer, 7:8))[] = htol(UInt16(5))
        
        @test buffer[1:8] == expected_buffer[1:8]
    end
    
    # @testset "Real Schema MessageHeader Test" begin
    #     # Load the real schema that now includes messageHeader
    #     schema = SBE.load_schema("test/example-schema.xml")
    #     
    #     # Verify messageHeader composite type is in the schema
    #     message_header_type = nothing
    #     for type_def in schema.types
    #         if type_def.name == "messageHeader"
    #             message_header_type = type_def
    #             break
    #         end
    #     end
    #     
    #     @test message_header_type !== nothing
    #     @test message_header_type isa Schema.CompositeType
    #     @test length(message_header_type.members) == 4
    #     @test message_header_type.members[1].name == "blockLength"
    #     @test message_header_type.members[2].name == "templateId"
    #     @test message_header_type.members[3].name == "schemaId"
    #     @test message_header_type.members[4].name == "version"
    #     
    #     # Try just loading the module without testing functionality yet
    #     # This will help isolate where the error is coming from
    #     baseline_module = nothing
    #     try
    #         baseline_module = SBE.load_schema_module(schema, "Baseline")
    #         @test baseline_module !== nothing
    #     catch e
    #         println("Error loading schema module: ", e)
    #         rethrow(e)
    #     end
    #     
    #     # Only test if module loaded successfully
    #     if baseline_module !== nothing
    #         @test isdefined(baseline_module, :MessageHeader)
    #         @test isdefined(baseline_module, :MessageHeaderDecoder)
    #         @test isdefined(baseline_module, :MessageHeaderEncoder)
    #     end
    # end
end
