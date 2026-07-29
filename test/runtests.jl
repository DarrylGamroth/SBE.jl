using Test

include(joinpath(@__DIR__, "..", "scripts", "sbetool_dependency.jl"))
using .SbeToolDependency: pinned_sbetool_version, selected_sbetool_version

include("generate_test_schemas.jl")

const GENERATED_SCHEMA_PATHS = generate_test_schemas()

function expect_error(f::Function, needle::AbstractString)
    error = try
        f()
        nothing
    catch caught
        caught
    end
    @test error !== nothing
    @test occursin(needle, sprint(showerror, error))
end

function load_generated_schema(fixture_name::Symbol)
    host = Module(Symbol("Generated", fixture_name))
    Base.include(host, GENERATED_SCHEMA_PATHS[fixture_name])
    module_name = test_fixture_module_name(fixture_name)
    isdefined(host, module_name) || error(
        "Generated fixture $fixture_name did not define module $module_name",
    )
    return Base.invokelatest(getfield, host, module_name)
end

# Each generated codec is loaded once, in a private host module. Test files use
# these aliases instead of redefining generated modules in Main.
const Baseline = load_generated_schema(:Baseline)
const Extension = load_generated_schema(:Extension)
const Optional = load_generated_schema(:Optional)
const Versioned = load_generated_schema(:Versioned)
const CodeGenerationTest = load_generated_schema(:CodeGenerationTest)
const OrderCheck = load_generated_schema(:OrderCheck)
const CompositeElements = load_generated_schema(:CompositeElements)
const Issue505 = load_generated_schema(:Issue505)
const Issue889 = load_generated_schema(:Issue889)
const SinceDeprecated = load_generated_schema(:SinceDeprecated)
const SinceVersionFilter = load_generated_schema(:SinceVersionFilter)
const DeprecatedMessage = load_generated_schema(:DeprecatedMessage)
const ExplicitPackage = load_generated_schema(:ExplicitPackage)
const NpeSmallHeader = load_generated_schema(:NpeSmallHeader)
const BigEndianBaseline = load_generated_schema(:BigEndianBaseline)
const JsonPrinterSchema = load_generated_schema(:JsonPrinterSchema)
const BasicTypes = load_generated_schema(:BasicTypes)
const BasicVariableLength = load_generated_schema(:BasicVariableLength)
const ValueRefLowerCaseEnum = load_generated_schema(:ValueRefLowerCaseEnum)
const JsonPrinterBaseline = load_generated_schema(:JsonPrinterBaseline)
const ExtensionSchema = load_generated_schema(:ExtensionSchema)
const ConstantEnumFields = load_generated_schema(:ConstantEnumFields)
const ValueRefSchema = load_generated_schema(:ValueRefSchema)
const GroupWithData = load_generated_schema(:GroupWithData)
const MessageBlockLengthTest = load_generated_schema(:MessageBlockLengthTest)
const CompositeOffsets = load_generated_schema(:CompositeOffsets)
const EmbeddedLengthAndCount = load_generated_schema(:EmbeddedLengthAndCount)
const LowerCaseBitset = load_generated_schema(:LowerCaseBitset)
const FixedSizedPrimitiveArray = load_generated_schema(:FixedSizedPrimitiveArray)
const EncodingTypes = load_generated_schema(:EncodingTypes)
const GroupWithConstantFields = load_generated_schema(:GroupWithConstantFields)
const NestedCompositeName = load_generated_schema(:NestedCompositeName)
const Issue1007 = load_generated_schema(:Issue1007)
const Issue560 = load_generated_schema(:Issue560)
const Issue567 = load_generated_schema(:Issue567)
const Issue895 = load_generated_schema(:Issue895)
const Issue910 = load_generated_schema(:Issue910)
const Issue967 = load_generated_schema(:Issue967)
const Issue972 = load_generated_schema(:Issue972)
const Issue984 = load_generated_schema(:Issue984)
const Issue987 = load_generated_schema(:Issue987)
const Issue1028 = load_generated_schema(:Issue1028)
const Issue1057 = load_generated_schema(:Issue1057)
const Issue1066 = load_generated_schema(:Issue1066)
const Issue483 = load_generated_schema(:Issue483)
const Issue435 = load_generated_schema(:Issue435)
const Issue496 = load_generated_schema(:Issue496)
const Issue488Schema = load_generated_schema(:Issue488)
const Issue472 = load_generated_schema(:Issue472)
const Issue661 = load_generated_schema(:Issue661)
const Issue827 = load_generated_schema(:Issue827)
const Issue847 = load_generated_schema(:Issue847)
const Issue848 = load_generated_schema(:Issue848)
const Issue849 = load_generated_schema(:Issue849)

const TEST_FILES = [
    # Core functionality
    "test_core_api.jl",
    "test_file_generation.jl",
    "test_load_schema_macro.jl",
    # Generated codec features
    "test_vardata.jl",
    "test_sbe_frames.jl",
    "test_groups.jl",
    "test_constants.jl",
    "test_display.jl",
    "test_enum_value_attribute.jl",
    "test_reserved_identifiers.jl",
    "test_version_handling.jl",
    "test_version_all_types.jl",
    "test_nested_types_in_composites.jl",
    "test_nested_sets_in_composites.jl",
    "test_optional_fields.jl",
    "test_consistent_field_api.jl",
    "test_generated_api.jl",
    "test_ir_decoder.jl",
    "test_ir_codegen.jl",
    "test_ir_utils.jl",
    # Integration and upstream parity
    "test_complex_patterns.jl",
    "test_allocations.jl",
    "test_java_fixtures.jl",
    "test_java_mirror.jl",
    "test_java_generation_parity.jl",
    "test_fixed_size_blob.jl",
    "test_constant_enum_fields.jl",
    "test_value_ref_schema.jl",
    "test_group_with_data.jl",
    "test_message_block_length.jl",
    "test_composite_offsets.jl",
    "test_embedded_length_and_count.jl",
    "test_lower_case_bitset.jl",
    "test_fixed_sized_primitive_array.jl",
    "test_encoding_types.jl",
    "test_group_with_constant_fields.jl",
    "test_nested_composite_name.jl",
    "test_issue1007.jl",
    "test_issue560.jl",
    "test_issue567.jl",
    "test_issue895.jl",
    "test_issue910.jl",
    "test_issue967.jl",
    "test_issue972.jl",
    "test_issue984.jl",
    "test_issue987.jl",
    "test_issue1028.jl",
    "test_issue1057.jl",
    "test_issue1066.jl",
    "test_issue889.jl",
    "test_since_deprecated.jl",
    "test_since_version_filter.jl",
    "test_deprecated_message.jl",
    "test_explicit_package.jl",
    "test_npe_small_header.jl",
    "test_bigendian_schema.jl",
    "test_json_printer_schema.jl",
    "test_basic_types_schema.jl",
    "test_basic_variable_length_schema.jl",
    "test_issue483.jl",
    "test_issue435.jl",
    "test_issue496.jl",
    "test_issue488.jl",
    "test_issue472.jl",
    "test_issue661.jl",
    "test_issue827.jl",
    "test_issue847.jl",
    "test_issue848.jl",
    "test_issue849.jl",
    "test_error_paths.jl",
    "test_sbetool_schema_compat.jl",
    "test_error_handlers.jl",
    "test_aqua.jl",
]

function selected_test_files()
    selection = strip(get(ENV, "SBE_TEST_FILES", ""))
    entries = isempty(selection) ? ARGS : split(selection, ',')
    isempty(entries) && return TEST_FILES

    requested = Set(
        endswith(name, ".jl") ? name : name * ".jl"
        for entry in entries
        for name in (strip(entry),)
        if !isempty(name)
    )
    unknown = setdiff(requested, Set(TEST_FILES))
    isempty(unknown) || error("Unknown test selections: $(join(sort!(collect(unknown)), ", "))")
    return filter(in(requested), TEST_FILES)
end

@testset "SBE.jl Tests" begin
    for test_file in selected_test_files()
        include(joinpath(@__DIR__, test_file))
    end
end
