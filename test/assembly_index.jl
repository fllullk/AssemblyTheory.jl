# Test the retained certificate as well as the public value; no witness shape
# is assumed unless the target forces reuse. This internal API is not exported.
function check_exact_witness(system, target, expected)
    result = AssemblyTheory._assembly_index_solution(system, target)
    @test assembly_index(system, target) == expected
    @test result.index == expected == length(result.construction.steps)
    @test verify(system, result.construction)
    @test object_equal(system, reference_object(system, result.construction,
                                               result.target_reference), target)
    @test length(ancestor_steps(system, result.construction, result.target_reference)) == expected
    return result
end

@testset "Exact integer assembly index" begin
    system = IntegerAdditionSystem()
    for (target, expected) in ((1, 0), (2, 1), (3, 2), (4, 2), (5, 3), (6, 3),
                               (7, 4), (8, 3), (9, 4), (10, 4), (11, 5), (12, 4),
                               (15, 5), (16, 4))
        check_exact_witness(system, big(target), expected)
    end
    @test assembly_index(system, 7) == 4 # Machine integers accepted at the API.
    primitive = AssemblyTheory._assembly_index_solution(system, big(1))
    @test isempty(primitive.construction.steps)
    @test primitive.target_reference == 1
    reused = check_exact_witness(system, big(8), 3)
    @test all(step -> step.left == step.right, reused.construction.steps)

    # A non-star extension: 16 requires 8+8 here, excluding the last value 9.
    # This tests that the integer search really considers all earlier pairs.
    available = BigInt[1, 2, 4, 8, 9]
    steps = [AssemblyStep(1, 1, big(2)), AssemblyStep(2, 2, big(4)),
             AssemblyStep(3, 3, big(8)), AssemblyStep(4, 1, big(9))]
    @test AssemblyTheory._addition_chain!(system, big(16), available, steps, 1,
                                         AssemblyTheory._ExactSearchBudget(100))
    @test (steps[end].left, steps[end].right) == (4, 4)
    @test verify(system, Construction(steps))
    @test steps[end].product == 16
end

@testset "Exact unrestricted string assembly index" begin
    system = DirectedStringSystem()
    for (target, expected) in (("L", 0), ("U", 0), ("LL", 1), ("LU", 1), ("UL", 1),
                               ("LLL", 2), ("LUL", 2), ("LLUL", 3), ("LLULL", 3),
                               ("LLLL", 2), ("LULU", 2), ("LULULU", 3), ("LLLLLLLL", 3))
        check_exact_witness(system, target, expected)
    end
    repeated = check_exact_witness(system, "LULU", 2)
    @test repeated.construction.steps[end].left == repeated.construction.steps[end].right

    # Independent fragment costs overcount the LL reused inside ULL.
    # LL (one join), ULL (two joins), final join: four versus three with sharing.
    shared = check_exact_witness(system, "LLULL", 3)
    @test assembly_index(system, "LL") + assembly_index(system, "ULL") + 1 == 4
    final_step = shared.construction.steps[end]
    left_ancestors = ancestor_steps(system, shared.construction, final_step.left)
    right_ancestors = ancestor_steps(system, shared.construction, final_step.right)
    @test !isempty(intersect(left_ancestors, right_ancestors))

    # Configured, duplicate, and irrelevant primitives retain reference order.
    configured = DirectedStringSystem(["XXXXXX", "U", "LL", "U"])
    @test building_blocks(configured) == ["XXXXXX", "U", "LL", "U"]
    primitive = check_exact_witness(configured, "LL", 0)
    @test primitive.target_reference == 3
    check_exact_witness(configured, "LLULL", 2)
    check_exact_witness(DirectedStringSystem(["LU"]), "LULU", 1)
    check_exact_witness(DirectedStringSystem(["L", "UU"]), "LUU", 1)
    check_exact_witness(DirectedStringSystem(["α", "β"]), "αβαβ", 2)
    @test assembly_index(system, SubString("XLLULLX", 2, 6)) == 3
end

struct UnsupportedIndexSystem <: AbstractAssemblySystem{String} end

@testset "Exact search rejects unsupported or unproved results" begin
    integers = IntegerAdditionSystem()
    strings = DirectedStringSystem()
    for target in (0, -1, "7", 7.0)
        @test_throws ArgumentError assembly_index(integers, target)
    end
    for target in ("", "X", 7)
        @test_throws ArgumentError assembly_index(strings, target)
    end
    for rule in (HigherLCount(), HigherLProportion())
        unsupported = DirectedStringSystem(; rule)
        @test_throws ArgumentError assembly_index(unsupported, "LLULL")
        @test_throws ArgumentError assembly_index(unsupported, "L")
    end
    @test_throws ArgumentError assembly_index(UnsupportedIndexSystem(), "L")
    # Alphabet-valid but unreachable, after exhausting the finite state graph.
    @test_throws ArgumentError assembly_index(DirectedStringSystem(["LL"]; alphabet="LU"), "L")
    @test_throws ArgumentError assembly_index(DirectedStringSystem(["L", "UU"]), "UL")

    for (system, target) in ((integers, big(7)), (strings, "LLULL"))
        @test_throws ArgumentError assembly_index(system, target; max_states=0)
        @test_throws ArgumentError assembly_index(system, target; max_states=-1)
        err = try
            assembly_index(system, target; max_states=1)
        catch caught
            caught
        end
        @test err isa ExactSearchLimitError
        if err isa ExactSearchLimitError
            @test err.max_states == 1
            @test occursin("optimality is unproved", sprint(showerror, err))
        end
    end
    # A failure cannot corrupt later searches; primitives need no search.
    @test assembly_index(integers, 7) == 4
    @test assembly_index(strings, "LLULL") == 3
    @test assembly_index(integers, 1; max_states=1) == 0
    @test assembly_index(strings, "L"; max_states=1) == 0
end
