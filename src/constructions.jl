"""
    AssemblyStep(left, right, product)

A claimed binary join with explicit integer operand references. References
`1:B` denote the system's ordered building blocks; `B+i` denotes step `i`.
Only building blocks and earlier steps may be referenced. References are checked
by `verify`, so invalid claims can be represented and inspected.
"""
struct AssemblyStep{T}
    left::Int
    right::Int
    product::T
end

"""
    Construction(steps)

An ordered vector of assembly claims with a common object type. Objects remain
available after use, including when used twice in the same join. An empty
construction can be written as `Construction(AssemblyStep{String}[])`.
Interpret a construction relative to a system's ordered building blocks; it does
not store that configuration. Equal products at different references retain
distinct histories. No target or optimality claim is implicit in a construction.
"""
struct Construction{T}
    steps::Vector{AssemblyStep{T}}
end

function _check_reference(system, construction, ref::Integer)
    total = length(building_blocks(system)) + length(construction.steps)
    1 <= ref <= total || throw(ArgumentError("reference $ref is outside 1:$total"))
    return nothing
end

"""
    reference_object(system, construction, ref)

Return the primitive or claimed step product at `ref`. This inspects a claim;
it does not verify its validity or assembly history. Invalid reference numbers
throw `ArgumentError`.
"""
function reference_object(system::AbstractAssemblySystem{T}, construction::Construction{T},
                          ref::Integer) where {T}
    _check_reference(system, construction, ref)
    blocks = building_blocks(system)
    return ref <= length(blocks) ? blocks[ref] : construction.steps[ref - length(blocks)].product
end

"""
    parent_references(system, construction, ref)

Return `()` for a primitive or `(left, right)` for a claimed step. Repeated
operands remain repeated: parent references preserve construction history,
independently of object equality. This inspects stored parents without verifying
them; invalid `ref` numbers throw `ArgumentError`.
"""
function parent_references(system::AbstractAssemblySystem{T}, construction::Construction{T},
                           ref::Integer) where {T}
    _check_reference(system, construction, ref)
    nblocks = length(building_blocks(system))
    ref <= nblocks && return ()
    step = construction.steps[ref - nblocks]
    return (step.left, step.right)
end

"""
    ancestor_steps(system, construction, targets)

Select one integer target reference or an iterable of references. Return the
one-based step indices needed for those targets, including each target's own
producing step, once each in construction order. Primitive targets need no steps;
an empty selection returns `Int[]`. Later unrelated steps are excluded.

Reject invalid target numbers and unavailable parents in the selected history
with `ArgumentError`. Assembly rules are not checked here; use `verify` for
feasibility of the full construction, including steps outside this selection.
"""
function ancestor_steps(system::AbstractAssemblySystem{T}, construction::Construction{T},
                        targets) where {T}
    selected = targets isa Integer ? (targets,) : targets
    nblocks = length(building_blocks(system))
    pending = Int[]
    for ref in selected
        ref isa Integer || throw(ArgumentError("targets must be integer references"))
        _check_reference(system, construction, ref)
        push!(pending, ref)
    end
    seen = falses(length(construction.steps))
    while !isempty(pending)
        ref = pop!(pending)
        ref <= nblocks && continue
        index = ref - nblocks
        seen[index] && continue
        step = construction.steps[index]
        for parent in (step.left, step.right)
            1 <= parent < ref || throw(ArgumentError("reference $ref has unavailable parent $parent"))
            push!(pending, parent)
        end
        seen[index] = true
    end
    return findall(seen)
end
