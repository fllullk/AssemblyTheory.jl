# Contributing

AssemblyTheory.jl is in early development. Keep changes small and dependencies
minimal. Discuss mathematical conventions and solver result semantics before
adding objectives, optimisation solvers, or simulation engines.

From the repository root, with Julia 1.10 or later:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=. examples/string_concatenation.jl
julia --project=. examples/integer_addition.jl
julia --project=. examples/assembly_index.jl
git diff --check
```

System extensions subtype `AbstractAssemblySystem{T}` and implement
`building_blocks`, `assembly_products`, and `is_valid_object`. Override
`object_equal` when ordinary `==` is inappropriate. Building-block order must
be stable because certificates reference it. Products must be distinct under
system equality and valid for the system. Keep verification independent of
solver search, and test both accepted and rejected certificates.

String rules subtype `AbstractStringRule` and implement
`assembly_products(rule, a, b)` for valid operands; the string system handles
alphabet validation. Test strict comparisons, ties, and duplicate products.
Do not reorder or deduplicate primitive lists. Parent references preserve
construction history independently of equality; ancestry selection must retain
repeated parents while returning shared ancestor steps only once.

Exact assembly-index solvers currently support integer addition from `1` and
unrestricted string concatenation. New search algorithms or supported models
need a completeness argument, justified pruning, independent witness verification,
and tests of both returned values and certificates. Do not present a resource
limit or an interrupted search as an exact optimum. An independently minimised
fragment cost does not account for sharing between its construction and another's.

Report feasibility, bounds, and exact optima distinctly. A short construction
alone is not proof of optimality. Document assumptions, tie rules, and equality
semantics alongside new systems. Preserve the license, existing user work, and
assets; avoid committing generated manifests for this package.
