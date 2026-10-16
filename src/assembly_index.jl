"""Exact search exhausted `max_states` state visits without proving an optimum."""
struct ExactSearchLimitError <: Exception
    max_states::Int
end

Base.showerror(io::IO, err::ExactSearchLimitError) =
    print(io, "exact assembly-index search exceeded max_states=", err.max_states,
          "; optimality is unproved and no assembly index was returned")

mutable struct _ExactSearchBudget
    max_states::Int
    visited::Int
    function _ExactSearchBudget(max_states::Int)
        max_states > 0 || throw(ArgumentError("max_states must be positive"))
        return new(max_states, 0)
    end
end

function _visit!(budget::_ExactSearchBudget)
    budget.visited < budget.max_states || throw(ExactSearchLimitError(budget.max_states))
    budget.visited += 1
    return nothing
end

"""
    assembly_index(system, target; max_states=100_000) -> Int

Return the proven minimum number of reusable binary joins needed for one target.
Primitives cost zero. Supported models are `IntegerAdditionSystem()` (positive
integer targets, primitive `BigInt[1]`) and `DirectedStringSystem` with
`UnrestrictedConcatenation()` (nonempty string targets, configured primitives).
Other systems/rules and invalid or unreachable targets raise `ArgumentError`.

The integer algorithm exhausts increasing addition chains by iterative depth;
the string algorithm searches available-object sets breadth first. Both retain
and independently verify a witness before returning. `max_states` is a positive
`Int`: it limits integer DFS visits across all depths or discovered string BFS
states, including the initial search state. Exceeding it throws
`ExactSearchLimitError`, never returns an estimate. These searches are intended
for small inputs; see docs/mathematical_conventions.md for proofs and limitations.
"""
assembly_index(system::AbstractAssemblySystem, target; max_states::Int=100_000) =
    _assembly_index_solution(system, target; max_states).index

function _assembly_index_solution(system::AbstractAssemblySystem, target; max_states::Int=100_000)
    throw(ArgumentError("exact assembly index supports only IntegerAdditionSystem and " *
                        "DirectedStringSystem with UnrestrictedConcatenation; got $(typeof(system))"))
end

# The independent verifier proves witness feasibility. Exhaustive search, not
# this check, establishes minimality. Keep this internal result for witness tests.
function _checked_index_solution(system, target, steps, target_reference)
    construction = Construction(steps)
    verify(system, construction) || error("exact search produced an invalid construction")
    object_equal(system, reference_object(system, construction, target_reference), target) ||
        error("exact search witness does not produce the requested target")
    return (index=length(steps), construction=construction, target_reference=target_reference)
end

function _assembly_index_solution(system::IntegerAdditionSystem, target; max_states::Int=100_000)
    budget = _ExactSearchBudget(max_states)
    target isa Integer && is_valid_object(system, target) ||
        throw(ArgumentError("integer assembly-index targets must be positive integers"))
    target = big(target)
    available = building_blocks(system)
    steps = AssemblyStep{BigInt}[]
    target == available[1] && return _checked_index_solution(system, target, steps, 1)

    # At most doubling at each join gives ceil(log2(target)) as a lower bound.
    # Left-to-right binary construction takes at most 2*(bitlength-1) joins.
    lower = ndigits(target - 1; base=2)
    upper = 2 * (ndigits(target; base=2) - 1)
    for depth in lower:upper
        if _addition_chain!(system, target, available, steps, depth, budget)
            return _checked_index_solution(system, target, steps, length(available))
        end
    end
    error("exact addition search exhausted a proven feasible depth bound")
end

function _addition_chain!(system::IntegerAdditionSystem, target::BigInt,
                          available::Vector{BigInt}, steps::Vector{AssemblyStep{BigInt}},
                          remaining::Int, budget::_ExactSearchBudget)
    _visit!(budget)
    available[end] == target && return true
    remaining == 0 && return false
    (available[end] << remaining) < target && return false

    # Every useful positive addition DAG can be sorted by increasing value.
    # Consider ALL pairs, not just pairs containing the most recent value.
    # Equal new values have identical futures with reusable operands.
    seen_products = Set{BigInt}()
    for right in length(available):-1:1, left in right:-1:1
        product = only(assembly_products(system, available[left], available[right]))
        available[end] < product <= target || continue
        product in seen_products && continue
        push!(seen_products, product)
        push!(available, product)
        push!(steps, AssemblyStep(left, right, product))
        _addition_chain!(system, target, available, steps, remaining - 1, budget) && return true
        pop!(steps)
        pop!(available)
    end
    return false
end

function _assembly_index_solution(system::DirectedStringSystem{UnrestrictedConcatenation},
                                 target; max_states::Int=100_000)
    budget = _ExactSearchBudget(max_states)
    target isa AbstractString && is_valid_object(system, target) ||
        throw(ArgumentError("string assembly-index targets must be nonempty words over the system alphabet"))
    target = String(target)
    blocks = building_blocks(system)
    steps = AssemblyStep{String}[]
    primitive = findfirst(block -> object_equal(system, block, target), blocks)
    primitive === nothing || return _checked_index_solution(system, target, steps, primitive)

    # Keep actual availability in reference order. Sort only copies for state
    # keys: merging equal sets is valid here because future joins depend solely
    # on available objects, not on which history first produced them.
    queue = [(available=blocks, steps=steps)]
    visited = Set{Tuple{Vararg{String}}}([Tuple(sort(unique(blocks)))])
    _visit!(budget)
    head = 1
    while head <= length(queue)
        node = queue[head]
        head += 1
        for right in eachindex(node.available), left in 1:right
            for product in assembly_products(system, node.available[left], node.available[right])
                # Every ancestor of a concatenation target is a contiguous
                # substring. Reconstructing an available object is redundant.
                occursin(product, target) || continue
                product in node.available && continue
                next_available = [node.available; product]
                key = Tuple(sort(unique(next_available)))
                key in visited && continue
                _visit!(budget)
                next_steps = [node.steps; AssemblyStep(left, right, product)]
                if object_equal(system, product, target)
                    return _checked_index_solution(system, target, next_steps, length(next_available))
                end
                push!(visited, key)
                push!(queue, (available=next_available, steps=next_steps))
            end
        end
    end
    throw(ArgumentError("target is not constructible from the ordered building blocks by unrestricted concatenation"))
end
