# AssemblyTheory.jl

<img src="assets/logo.svg" alt="AssemblyTheory logo" width="280">

An extensible Julia package for assembly optimisation and stochastic simulation,
built around shared system interfaces and specialised solvers.

**Early development:** the package provides configurable directed strings, integer
addition, explicit constructions, independent verification, and exact assembly
indices for small inputs in two supported models. Broader optimisation and
simulation engines remain future work.

## Implemented

- Ordered string building blocks, derived or explicit character alphabets, and
  exact string equality. `DirectedStringSystem()` preserves the `["L", "U"]` default.
- Separate rules for unrestricted concatenation, higher L count on the left, or
  higher L proportion on the left. Ties permit both distinct orders; proportion
  comparisons are exact. These restrict products, not sampling probabilities.
- Generic constructions with explicit parent references and reusable intermediates.
- Object, parent, and ancestor inspection for one or multiple target references,
  including primitives and earlier outputs.
- Verification of object validity, operand availability, and assembly rules.
- Positive integer addition using the same certificates and verifier.
- Exact single-target assembly index for integer addition from `BigInt[1]` and
  directed strings under unrestricted concatenation, with verified witnesses.

The small multiple-dispatch interface separates building blocks, assembly rules,
validity constraints, and equality from construction verification. A verified
construction certifies feasibility; it does not establish a minimum step count.

```julia
using AssemblyTheory

system = DirectedStringSystem(["L", "U"]; rule=HigherLProportion())
construction = Construction([
    AssemblyStep(1, 2, "LU"),   # Ref 3; refs 1 and 2 are the ordered primitives.
    AssemblyStep(3, 3, "LULU"), # Ref 4; using a reference twice is allowed.
])
verify(system, construction)                         # true
reference_object(system, construction, 4)             # "LULU"
parent_references(system, construction, 4)            # (3, 3)
ancestor_steps(system, construction, [1, 3, 4])        # [1, 2] (step indices)
```

A construction is interpreted relative to the system's **ordered building
blocks**; changing that order changes the references. Blocks are never silently
sorted or deduplicated. The alphabet is derived from block characters unless
specified explicitly, for example `DirectedStringSystem(["LL"]; alphabet="LU")`.
Here `L` and `U` are valid objects but neither is an available primitive.

Parent references preserve construction history. Equal objects produced by
different steps remain separate references, and repeated parents remain visible.
Ancestor inspection includes each selected target's producing step and shared
ancestors once; it does not merge equal objects or prove feasibility.

## Exact assembly index

```julia
assembly_index(IntegerAdditionSystem(), big(7)) # 4
assembly_index(DirectedStringSystem(), "LLULL") # 3
assembly_index(DirectedStringSystem(), "L")     # 0 (primitive)
```

The index is the proven minimum number of binary joins. Building blocks cost
zero, each join costs one, and every available object can be reused indefinitely.
The integer solver uses iterative deepening over all pairs of prior values,
including non-star additions. The unrestricted string solver uses breadth-first
search over sets of available target substrings, preserving shared intermediates
and string direction. It does not add independently minimised fragment costs.

For example, `LL`, then `ULL` using that `LL`, then `LLULL` takes three joins.
Building `LL` and `ULL` independently and adding one final join would count four.
Search establishes optimality; the existing verifier independently checks each
retained witness and its target. Internal witnesses are not yet a public API.

Exact search supports `IntegerAdditionSystem()` and string systems configured
with `UnrestrictedConcatenation()` only. Configured string primitives retain
their reference order. L-count and L-proportion rules remain usable for
construction and verification, but exact search rejects them with `ArgumentError`.
Invalid and unreachable targets also raise `ArgumentError`.

Both searches grow combinatorially and are intended for small targets. The
positive `Int` keyword `max_states` defaults to `100_000`: exceeding it throws
`ExactSearchLimitError`, with no estimate returned. For example,
`assembly_index(IntegerAdditionSystem(), 7; max_states=1)` fails explicitly.
Raising this limit permits more work; it does not guarantee timely completion.
This counts search states, not elapsed time or bytes. See the
[algorithm and exactness arguments](docs/mathematical_conventions.md#exact-assembly-index).

## Planned

Faster search and additional supported rules, depth optimisation, discrete
Dirichlet energy, joint assembly / COJAS, stochastic dynamics, external solver
adapters, further object types, and graph attachment machinery are future work.
See [the roadmap](docs/roadmap.md) and
[mathematical conventions](docs/mathematical_conventions.md).

## Local use

Requires Julia 1.10 or later. From the repository root:

```sh
julia --project=. -e "using Pkg; Pkg.instantiate()"
julia --project=. -e "using Pkg; Pkg.test()"
julia --project=. examples/string_concatenation.jl
julia --project=. examples/integer_addition.jl
julia --project=. examples/assembly_index.jl
```

To install this local checkout into a separate Julia environment, run
`using Pkg; Pkg.develop(path="/absolute/path/to/AssemblyTheory.jl")` in that
environment's Julia REPL. The package has no runtime dependencies.

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidance. Distributed
under the existing [MIT license](LICENSE).
