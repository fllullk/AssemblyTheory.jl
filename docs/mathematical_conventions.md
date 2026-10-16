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

The verifier replays these claims from the system definition, checking validity and rule
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

## Integer addition

`IntegerAdditionSystem()` has ordered building blocks `[big(1)]`, positive
integer validity, ordinary numerical equality, and a single product `a + b`.
Its object type is `BigInt`, so use `big(...)` step products (including in empty
`AssemblyStep{BigInt}[]` constructions). Arbitrary precision avoids overflow.
The generic construction representation, verifier, and inspection helpers are
used unchanged. The system also supports exact single-target assembly-index search.

## Exact assembly index

`assembly_index(system, target; max_states=100_000)` returns an `Int` equal to the
minimum number of binary joins needed to make one target available. Primitives
cost zero, each join costs one, and all objects remain reusable, including twice
within one join. Target primitives have index zero. This objective is separate
from depth and counts shared intermediates once, regardless of how often used.

Exact search supports only:

- `IntegerAdditionSystem()`, starting from `BigInt[1]`, for positive integer
  targets. Machine integer inputs are converted to `BigInt` internally.
- `DirectedStringSystem` with `UnrestrictedConcatenation()`, for nonempty words
  over its configured alphabet, relative to its configured ordered primitives.
  Character alphabets, multi-character blocks, duplicate primitives, and blocks
  irrelevant to the target are supported without changing their reference order.

All other system/rule combinations, including L-count and L-proportion rules,
raise `ArgumentError`, even for primitive targets. Invalid targets also raise
`ArgumentError`. A valid string that cannot be constructed raises `ArgumentError`
only after exhausting the finite relevant state graph; resource exhaustion
instead raises `ExactSearchLimitError`.

### Integer search and its proof

The solver uses iterative-deepening depth-first search over strictly increasing
addition chains. At every state it tries all unordered pairs of earlier values,
including a value paired with itself. A pair need not contain the most recently
constructed value: this is not restricted to Brauer/star chains.

Completeness and pruning follow from the supported positive-addition model:

1. Discard unused steps in an optimal construction. Every remaining value is at
   most the target because positive addition strictly increases both operands.
2. Duplicate constructions of an already available value are unnecessary because
   values are reusable. Keep one copy of each value.
3. Sort those constructed values numerically. Every parent is strictly smaller
   than its sum, so this gives a valid construction with the same cost. Thus
   searching only increasing chains loses no optimal solution.
4. A candidate must exceed the current maximum and not exceed the target. All
   pairs producing the same new value have identical future availability, so
   only one is explored at a given search node. Its explicit parents are retained.
5. With maximum available value `m` and `r` joins remaining, no construction can
   exceed `m * 2^r`. A branch below the target even at this bound is impossible.
   The comparison uses `BigInt`, avoiding overflow and floating-point rounding.

From primitive `1`, the doubling bound gives `ceil(log2(target))` as the first
possible depth, computed with integer bit lengths. Reading the target's binary
digits left to right gives a feasible construction with at most two joins per
bit after the leading bit (double, optionally add `1`). This supplies the finite
upper depth `2 * (bitlength(target) - 1)`. The solver tries every depth from the
lower bound upwards, fully exhausting every smaller feasible depth before
returning a witness. The first success is therefore a proven minimum. The
binary construction supplies only a bound, never a claimed exact answer.

### String search and its proof

The solver performs breadth-first search whose states are complete sets of
available objects, starting from the primitives. Each edge adds exactly one
permitted concatenation product at unit cost. It tries all unordered operand
pairs, including repeated operands; the unrestricted rule supplies both distinct
product orders. This retains all possible reusable sharing between fragments.

Only these reductions are applied:

1. A useful constructed ancestor of the target must be a contiguous substring
   of the target: each concatenation embeds both operands contiguously, and this
   property is transitive. Discarding non-substring products loses no optimum.
   Irrelevant primitives remain in their original reference positions.
2. Reconstructing an available object cannot help under unrestricted reuse, so
   additions must introduce a new object.
3. Histories with equal available-object sets have identical possible futures.
   Breadth-first search retains the first, least-cost representative of each
   set. Sorting and deduplication apply only to copied state keys, never to the
   actual primitives, references, or witness histories.

A finite word has finitely many substrings, so this search graph is finite.
Every useful construction corresponds to a path in it; breadth-first search
reaches the target at the shortest path length. If the entire queue is exhausted,
the target is unreachable in this model. No substring's independently computed
index is substituted for the state: shared histories can make fragment-cost
addition overcount. For instance, `LL`, `ULL`, `LLULL` takes three joins, while
building `LL` (one) and `ULL` (two) independently plus the final join counts four.

### Witnesses, limits, and interpretation

Both algorithms retain an ordinary `Construction` with explicit operand
references and a target reference. Before returning any index, the solver calls
the existing independent `verify` and checks that the target reference actually
equals the requested target. Primitive witnesses are empty constructions.
Witness feasibility alone does not prove optimality: exhaustive search in cost
order plus the completeness arguments above establish minimality. The internal
witness result is tested but is not yet a stable public API.

The positive `Int` keyword `max_states` defaults to `100_000`. It counts DFS
state visits across all integer depth iterations (including pruned nodes), or
newly discovered BFS states for strings, including the initial search state.
Primitive targets need no search visits. When another state would exceed the
budget, `ExactSearchLimitError` is thrown with no exact index or heuristic value
returned. No interrupted or budget-limited search is reported as an optimum.

These are simple combinatorial searches, not scalable general solvers. String
BFS stores available objects and a witness history for each discovered state;
integer DFS can revisit the same values along different chains and depths.
The state budget is not a wall-clock or byte limit, and increasing it may consume
substantial time and memory. Exact search has no persistent cache or lookup table.

## Feasibility and bounds

A verified construction containing a target can support an upper bound on its
minimum join count under these conventions. Verification alone proves neither
minimality nor a lower bound. Keep such feasible certificates and bounds distinct
from proven exact values returned by the supported exhaustive searches.

## Decisions deferred

Depth conventions, boundary conditions and normalisation for discrete Dirichlet
energy, and the precise joint assembly / COJAS objective remain to be specified.
Depth/energy optimisation, joint-target optimisation, stochastic simulation,
and graph attachment machinery remain unimplemented.
