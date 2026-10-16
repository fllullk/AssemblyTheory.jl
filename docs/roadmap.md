# Roadmap

Implemented: configurable directed strings; unrestricted, L-count, and exact
L-proportion concatenation rules (both distinct orders on ties); explicit reusable
construction histories; reference and multi-target ancestry inspection; generic
feasibility verification; positive integer addition; and exact single-target
assembly index for integer addition from `1` and unrestricted strings. Exact
search retains verified witnesses and fails explicitly on its state limit.

Future work:

- Faster exact search and justified support for additional systems and string rules.
- Constrained depth and discrete Dirichlet energy: specify objectives, depth
  counting, and energy boundary/normalisation conventions before implementing them.
- Joint assembly / COJAS: define multi-target costs and the intended formulation.
  Shared ancestry inspection alone does not implement joint optimisation.
- Stochastic dynamics: define populations, propensities, resource/copy semantics,
  and reproducibility independently of reusable certificate objects.
- External solver adapters with independently verified certificates and explicit
  termination status, bounds, and optimality evidence; avoid heavy core dependencies.
- Further object types and graph attachment machinery when concrete needs arise.

Keep exact results distinct from upper/lower bounds. Further optimisation, energy,
and simulation APIs remain unspecified; settle conventions before implementing them.
