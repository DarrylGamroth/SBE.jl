using SBE

schema_path = joinpath(@__DIR__, "..", "src", "resources", "sbe-ir.xml")
output_path = joinpath(@__DIR__, "..", "src", "generated", "sbe_ir.jl")

SBE.generate(schema_path, output_path)
println("Generated ", output_path)
