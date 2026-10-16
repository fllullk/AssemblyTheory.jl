# Roadmap

Implemented: configurable directed strings; unrestricted, L-count, and exact
L-proportion concatenation rules (both distinct orders on ties); explicit reusable
construction histories; reference and multi-target ancestry inspection; generic
feasibility verification; and a tiny positive integer-addition system.

Future work:

- Specialised string and integer addition-chain search and optimisation solvers.
- Assembly index, constrained depth, and discrete Dirichlet energy: specify
  objectives, depth counting, and energy boundary/normalisation conventions.
- Joint assembly / COJAS: define multi-target costs and the intended formulation.
  Shared ancestry inspection alone does not implement joint optimisation.
- Stochastic dynamics: define populations, propensities, resource/copy semantics,
  and reproducibility independently of reusable certificate objects.
- External solver adapters with independently verified certificates and explicit
  termination status, bounds, and optimality evidence; avoid heavy core dependencies.
- Further object types and graph attachment machinery when concrete needs arise.

Keep exact results distinct from upper/lower bounds. No optimisation, energy, or
simulation API is reserved yet; settle conventions before implementing it.
