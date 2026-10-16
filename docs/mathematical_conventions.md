# Mathematical conventions

## Configurable directed strings

`DirectedStringSystem(blocks; alphabet=nothing, rule=UnrestrictedConcatenation())`
accepts a nonempty ordered vector or tuple of nonempty strings. The default
blocks are `["L", "U"]`. Order and duplicate entries are preserved; configuration
is copied into immutable tuples. Unordered primitive sets are not accepted.

The default alphabet consists of all characters occurring in the blocks. An
explicit iterable of characters, including a string, may specify a larger
alphabet and must include every character of every block. Objects are nonempty
words over that alphabet. Validity is separate from primitive availability and
reachability: with blocks `["LL"]` and alphabet `"LU"`, both `L` and `U` are valid
but neither is initially available or constructible. Characters mean Julia
`Char` values, not bytes or grapheme clusters. Equality is exact string equality;
there is no Unicode normalisation, reversal, or cyclic equivalence.

## String rules

Rules implement `assembly_products(rule, a, b)` for valid operands, independently
of system configuration. The system checks operand validity before dispatching
to its rule. New rules subtype `AbstractStringRule`; no new system type is needed
for another combination of blocks and rule. Rule methods assume valid nonempty
operands; use the system method at the public validation boundary.

- `UnrestrictedConcatenation()`: distinct members of `[ab, ba]`, in encounter
  order. Joining `L` and `U` returns `["LU", "UL"]`; joining `L` and `LL` returns
  only `["LLL"]`, even though the operands differ.
- `HigherLCount()`: place the operand with more literal `L` characters on the
  left. Equal counts permit both distinct orders, with `ab` enumerated first.
- `HigherLProportion()`: place the operand with greater L count divided by
  character length on the left. Compare `L(a) * length(b)` and
  `L(b) * length(a)` using arbitrary-precision integer arithmetic, without
  floating-point rounding or multiplication overflow. Equal proportions permit
  both distinct orders, with `ab` enumerated first.

All characters other than literal `L` contribute only to the denominator. Thus
`LLUUU` goes before `L` under count ordering, while `L` goes first under proportion
ordering. `LU` and `LLUU` tie in proportion. Alphabets without `L` tie throughout.
These rules restrict permitted products and do not specify sampling probabilities.

## Construction certificates

References are one-based: `1:B` select building blocks in their declared order,
and `B+i` selects the claimed product of step `i`. Step `i` may reference only
blocks or steps strictly earlier than `i`. Both operands may be the same
reference. A join adds one product and consumes nothing; blocks and all earlier
products remain reusable indefinitely. There is no inventory or copy cost.

Constructions are interpreted relative to the system's ordered building blocks;
the construction does not store or fingerprint the system configuration. Never
silently reorder those blocks when interpreting an existing construction.

Each step records its two parent references and its claimed product. Parent
references preserve construction history independently of object identity. Equal
products at two references are not merged, and `(3, 3)` retains both uses of the
same operand. For restricted concatenation, the rule selects the permitted
product order; the stored parent tuple need not already be in that order.

The verifier
replays these claims from the system definition, checking validity and rule
membership with system-specific equality. It does not trust a solver's claims.
An empty construction is valid and represents only the initially available
blocks. A construction does not store a target or an optimality claim. The number
of recorded joins is a certificate length, not a computed assembly index.

## Reference and target inspection

`reference_object(system, construction, ref)` returns a primitive or claimed
product. `parent_references(...)` returns `()` for a primitive and `(left, right)`
for a step, including repeated references. These inspect claims without verifying
them. Out-of-range references raise `ArgumentError`.

`ancestor_steps(system, construction, targets)` accepts one reference or an
iterable of references, including primitive and earlier-output targets. It
returns **step indices**, not object references, including the targets' own
producing steps, in construction order. Each shared ancestor occurs once;
unrelated later steps are excluded. Primitive-only or empty selections return
`Int[]`. Selected self, forward, and invalid parent references raise
`ArgumentError`. Unselected history is not traversed, and rule membership is not
checked by inspection. `verify` checks the entire construction, even steps
outside selected target histories.

## Integer interface demonstration

`IntegerAdditionSystem()` has ordered building blocks `[big(1)]`, positive
integer validity, ordinary numerical equality, and a single product `a + b`.
Its object type is `BigInt`, so use `big(...)` step products (including in empty
`AssemblyStep{BigInt}[]` constructions). Arbitrary precision avoids overflow.
The generic construction representation, verifier, and inspection helpers are
used unchanged. This is an interface demonstration with no addition-chain search.

## Feasibility and future objectives

A verified construction containing a target can support an upper bound on its
minimum join count under these conventions. Verification alone proves neither
minimality nor a lower bound. Any future exact-result API must specify its
objective, target, assumptions, and evidence of optimality.

## Decisions deferred

Depth conventions, boundary conditions and normalisation for discrete Dirichlet
energy, and the precise joint assembly / COJAS objective remain to be specified.
There are no implemented optimisation objectives, energy calculations,
simulation engines, or graph attachment machinery.
