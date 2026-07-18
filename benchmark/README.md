# SBE.jl Benchmarks

From the repository root, set up the benchmark environment with:

```bash
julia --project=benchmark -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
```

Run:

```bash
julia --project=benchmark benchmark/benchmarks.jl
```

Options:

- Set `SBE_BENCH_OUT` to write a stable summary file (default: benchmark/results.txt).

The suite reports both setup-inclusive and reusable-flyweight paths:

- `encode_construct` and `decode_construct` create codec state for each operation.
- `encode_reuse` and `decode_reuse` retain codec state and rewrap caller-owned buffers.

Compare branches by running the suite on each revision with the same Julia version,
hardware, power settings, and workload parameters. Treat generated `results.txt` as
a local artifact rather than committed source.
