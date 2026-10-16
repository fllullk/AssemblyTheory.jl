module AssemblyTheory

export AbstractAssemblySystem, DirectedStringSystem, IntegerAdditionSystem,
       AbstractStringRule, UnrestrictedConcatenation, HigherLCount, HigherLProportion,
       building_blocks, assembly_products, is_valid_object, object_equal,
       AssemblyStep, Construction, reference_object, parent_references, ancestor_steps, verify,
       assembly_index, ExactSearchLimitError

include("systems.jl")
include("constructions.jl")
include("verification.jl")
include("assembly_index.jl")

end
