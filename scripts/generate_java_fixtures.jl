#!/usr/bin/env julia
using Downloads

function java_executable(name)
    exe = Sys.which(name)
    exe === nothing && error("Missing $(name) executable in PATH.")
    return exe
end

function collect_java_sources(dir::AbstractString)
    sources = String[]
    for (root, _, files) in walkdir(dir)
        for file in files
            endswith(file, ".java") || continue
            push!(sources, joinpath(root, file))
        end
    end
    return sources
end

function main()
    root_dir = normpath(joinpath(@__DIR__, ".."))
    sbe_version = get(ENV, "SBE_VERSION", "1.36.2")
    sbe_cache_dir = get(ENV, "SBE_CACHE_DIR", joinpath(homedir(), ".cache", "sbe"))
    sbe_group = "uk/co/real-logic"
    sbe_artifact = "sbe-all"
    sbe_default = joinpath(sbe_cache_dir, "$(sbe_artifact)-$(sbe_version).jar")
    sbe_jar = get(ENV, "SBE_JAR_PATH", sbe_default)
    sbe_url = "https://repo1.maven.org/maven2/$(sbe_group)/$(sbe_artifact)/$(sbe_version)/" *
              "$(sbe_artifact)-$(sbe_version).jar"

    schema = joinpath(root_dir, "test", "example-schema.xml")
    ext_schema = joinpath(root_dir, "test", "example-extension-schema.xml")
    codegen_schema = joinpath(root_dir, "test", "resources", "java-code-generation-schema.xml")

    out_dir = joinpath(root_dir, "test", "java-fixtures", "generated")
    class_dir = joinpath(root_dir, "test", "java-fixtures", "classes")
    fixture_out = joinpath(root_dir, "test", "java-fixtures", "car-example.bin")
    ext_fixture_out = joinpath(root_dir, "test", "java-fixtures", "car-extension.bin")
    codegen_fixture_out = joinpath(root_dir, "test", "java-fixtures", "codegen-global-keywords.bin")

    isdir(out_dir) && rm(out_dir; recursive=true, force=true)
    isdir(class_dir) && rm(class_dir; recursive=true, force=true)
    mkpath(out_dir)
    mkpath(class_dir)
    mkpath(dirname(fixture_out))
    mkpath(dirname(sbe_jar))

    if !isfile(sbe_jar)
        println("Downloading sbe-all $(sbe_version)...")
        Downloads.download(sbe_url, sbe_jar)
    end

    java = java_executable("java")
    javac = java_executable("javac")
    java_opts = ["--add-opens=java.base/jdk.internal.misc=ALL-UNNAMED"]
    codegen_opts = ["-Dsbe.keyword.append.token=_", "-Dsbe.target.language=java", "-Dsbe.output.dir=$(out_dir)"]

    run(Cmd([java; java_opts; codegen_opts; ["-jar", sbe_jar, schema]...]))
    run(Cmd([java; java_opts; codegen_opts; ["-jar", sbe_jar, ext_schema]...]))
    run(Cmd([java; java_opts; codegen_opts; ["-jar", sbe_jar, codegen_schema]...]))

    java_sources = collect_java_sources(out_dir)
    generator_sources = [
        joinpath(root_dir, "scripts", "GenerateCarFixture.java"),
        joinpath(root_dir, "scripts", "GenerateExtensionFixture.java"),
        joinpath(root_dir, "scripts", "GenerateCodeGenFixture.java"),
        joinpath(root_dir, "scripts", "VerifyCarFixture.java"),
    ]

    compile_cmd = Cmd([javac, "-cp", sbe_jar, "-d", class_dir, java_sources..., generator_sources...])
    run(compile_cmd)

    run(Cmd([java; java_opts; ["-cp", "$(sbe_jar):$(class_dir)", "GenerateCarFixture", fixture_out]...]))
    run(Cmd([java; java_opts; ["-cp", "$(sbe_jar):$(class_dir)", "GenerateExtensionFixture", ext_fixture_out]...]))
    run(Cmd([java; java_opts; ["-cp", "$(sbe_jar):$(class_dir)", "GenerateCodeGenFixture", codegen_fixture_out]...]))

    println("Wrote fixture to $(fixture_out)")
    println("Wrote fixture to $(ext_fixture_out)")
    println("Wrote fixture to $(codegen_fixture_out)")
end

main()
