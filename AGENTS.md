# Repository instructions

- Preserve the existing LICENSE, .gitignore, assets, and user changes.
- Current scope includes configurable directed strings, separate unrestricted,
  higher-L-count, and exact higher-L-proportion rules, a tiny integer-addition
  demonstration, explicit operand references, ancestry inspection, and independent
  construction verification. Both ordering rules allow both distinct orders on
  ties. These restrict products, not sampling probabilities.
- Exact single-target assembly index is supported for IntegerAdditionSystem
  from BigInt[1] and DirectedStringSystem with UnrestrictedConcatenation only.
  Reuse the generic certificates and independent verifier. Document completeness
  and every pruning rule; never report heuristic or interrupted results as exact.
  Resource exhaustion must fail explicitly. Keep other rule combinations unsupported
  until their search completeness is justified. Test values and witness certificates.
- Keep validity separate from primitive availability. Interpret every construction
  relative to its system's ordered building blocks; never silently sort or
  deduplicate them. Document derived and explicit alphabets.
- Parent references preserve history independently of object equality. Retain
  repeated operands and reusable intermediates; joining consumes nothing. Target
  ancestry may select primitives or earlier outputs and returns shared steps once.
- Use small shared interfaces and Julia multiple dispatch with specialised
  implementations. Avoid speculative abstractions and unnecessary dependencies.
- Broader optimisation solvers, simulation engines, energy calculations, depth
  objectives, joint assembly / COJAS, external solver adapters, graph attachment
  machinery, and further object types are future work. Document
  proposals before expanding scope; do not claim these are implemented.
- Always distinguish exact results from bounds. Feasibility verification does
  not prove optimality. Label upper/lower bounds and document assumptions and
  optimality evidence whenever an exact result is claimed.
- Maintain independent certificate verification as solvers are introduced.
- Run `julia --project=. -e 'using Pkg; Pkg.test()'` and
  both `julia --project=. examples/string_concatenation.jl` and
  `julia --project=. examples/integer_addition.jl` after relevant changes.
  Also run `julia --project=. examples/assembly_index.jl` for exact-index changes.
  Use `julia --project=. -e 'using Pkg; Pkg.instantiate()'` for local setup.
  Run `git diff --check`. If Julia is unavailable, report runtime verification
  as incomplete rather than implying the tests passed.
- Keep README capabilities and docs/mathematical_conventions.md consistent with
  actual behavior; record deferred mathematical decisions in docs/roadmap.md.
