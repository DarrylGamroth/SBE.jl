module SbeToolDependency

export pinned_sbetool_version, selected_sbetool_version

const SBETOOL_POM = normpath(joinpath(@__DIR__, "..", "test", "sbetool", "pom.xml"))
const SBETOOL_VERSION_PATTERN =
    r"<sbe\.version>\s*(?<version>[^<\s]+)\s*</sbe\.version>"

function validate_sbetool_version(value::AbstractString)
    version = String(value)
    tryparse(VersionNumber, version) === nothing &&
        error("invalid SbeTool version: $(repr(version))")
    return version
end

function pinned_sbetool_version()
    match_result = match(SBETOOL_VERSION_PATTERN, read(SBETOOL_POM, String))
    match_result === nothing &&
        error("missing <sbe.version> in $(SBETOOL_POM)")
    return validate_sbetool_version(match_result[:version])
end

function selected_sbetool_version()
    version = get(ENV, "SBE_VERSION", nothing)
    version === nothing && return pinned_sbetool_version()
    return validate_sbetool_version(version)
end

end
