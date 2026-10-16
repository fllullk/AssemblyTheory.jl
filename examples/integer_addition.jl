using AssemblyTheory

# A demonstration of the shared interface, not an addition-chain solver.
system = IntegerAdditionSystem()
construction = Construction([
    AssemblyStep(1, 1, big(2)), # Primitive 1 is reference 1; result is reference 2.
    AssemblyStep(2, 2, big(4)), # Reuse 2 twice; result is reference 3.
    AssemblyStep(3, 2, big(6)), # Both 4 and 2 remain available.
])

@assert verify(system, construction)
@assert reference_object(system, construction, 4) == 6
@assert parent_references(system, construction, 3) == (2, 2)
@assert ancestor_steps(system, construction, [1, 3]) == [1, 2]
println("Verified integer construction ending at ", reference_object(system, construction, 4))
println("Steps for earlier target 4 (reference 3): ", ancestor_steps(system, construction, 3))
println("Feasibility verified; no search or optimality proof performed.")
