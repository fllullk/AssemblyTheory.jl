using AssemblyTheory

system = DirectedStringSystem()
construction = Construction([
    AssemblyStep(1, 2, "LU"),     # Building blocks L and U; result is reference 3.
    AssemblyStep(3, 3, "LULU"),   # Reuse LU twice; result is reference 4.
    AssemblyStep(3, 1, "LUL"),    # LU and L are still available.
])

@assert assembly_products(system, "L", "U") == ["LU", "UL"]
@assert verify(system, construction)
println("Allowed joins of L and U: ", assembly_products(system, "L", "U"))
println("Verified ", length(construction.steps), " steps; final product: ",
        construction.steps[end].product)
println("Feasibility verified; no optimality claim is made.")

# Targets may be earlier outputs, primitives, or several references together.
@assert reference_object(system, construction, 4) == "LULU"
@assert parent_references(system, construction, 4) == (3, 3)
@assert ancestor_steps(system, construction, 4) == [1, 2]
@assert ancestor_steps(system, construction, [1, 4, 5]) == [1, 2, 3]
println("Steps needed for reference 4: ", ancestor_steps(system, construction, 4))

# Change blocks, alphabet, or rule independently. A valid L is not a primitive
# here: only LL and U are initially available, in precisely that order.
configured = DirectedStringSystem(["LL", "U"]; alphabet="LUX", rule=HigherLCount())
@assert building_blocks(configured) == ["LL", "U"]
@assert is_valid_object(configured, "X")
@assert verify(configured, Construction([AssemblyStep(2, 1, "LLU")]))

by_count = DirectedStringSystem(; rule=HigherLCount())
by_proportion = DirectedStringSystem(; rule=HigherLProportion())
@assert assembly_products(by_count, "LLUUU", "L") == ["LLUUUL"]
@assert assembly_products(by_proportion, "LLUUU", "L") == ["LLLUUU"]
@assert assembly_products(by_proportion, "LU", "LLUU") == ["LULLUU", "LLUULU"]
println("Count and proportion rules restrict permitted products; ties allow both orders.")
