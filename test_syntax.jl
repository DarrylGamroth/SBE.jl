#!/usr/bin/env julia
"""
Minimal syntax check for the new IR code without requiring package installation
"""

println("Checking IR.jl syntax...")
include("src/IR.jl")
println("✓ IR.jl syntax OK")

println("\nChecking Schema.jl syntax...")
include("src/Schema.jl")
println("✓ Schema.jl syntax OK")

println("\nAll syntax checks passed!")
