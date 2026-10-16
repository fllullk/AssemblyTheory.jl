"""
    verify(system, construction) -> Bool

Independently replay a construction from the system's building blocks. Check
object validity, operand availability, and membership of each claimed product
in `assembly_products`, using `object_equal`. No operands are consumed.
Returns `false` for an invalid claim; errors in system interface implementations
are allowed to propagate. This checks feasibility only, never optimality.
"""
function verify(system::AbstractAssemblySystem{T}, construction::Construction{T}) where {T}
    available = T[block for block in building_blocks(system)]
    all(block -> is_valid_object(system, block), available) || return false

    for step in construction.steps
        1 <= step.left <= length(available) || return false
        1 <= step.right <= length(available) || return false
        is_valid_object(system, step.product) || return false
        products = assembly_products(system, available[step.left], available[step.right])
        any(product -> object_equal(system, product, step.product), products) || return false
        push!(available, step.product)
    end
    return true
end
