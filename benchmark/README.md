SBE.jl Benchmarks

Setup:
1) julia --project=benchmark -e 'using Pkg; Pkg.develop(path=".."); Pkg.instantiate()'

Run:
1) julia --project=benchmark benchmark/benchmarks.jl

Options:
- Set `SBE_BENCH_OUT` to write a stable summary file (default: benchmark/results.txt).

Branch comparison:
- On the `wrap` branch, `benchmark/benchmarks.jl` benchmarks the wrap-based reuse API.
- On the base branch, `benchmark/benchmarks.jl` benchmarks the constructor/rewind API.
