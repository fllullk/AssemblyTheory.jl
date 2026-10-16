using Test
using AssemblyTheory

# A rule extension needs no new system type.
struct LeftOnly <: AbstractStringRule end
AssemblyTheory.assembly_products(::LeftOnly, a::AbstractString, b::AbstractString) = [string(a, b)]

@testset "Directed strings" begin
    system = DirectedStringSystem()
    @test building_blocks(system) == ["L", "U"]
    blocks = building_blocks(system)
    blocks[1] = "changed"
    @test building_blocks(system) == ["L", "U"]
    @test is_valid_object(system, "LUL")
    @test !is_valid_object(system, "")
    @test !is_valid_object(system, "LX")
    @test !is_valid_object(system, 1)
    @test !object_equal(system, "LU", "UL")
    @test assembly_products(system, "L", "U") == ["LU", "UL"]
    @test assembly_products(system, "U", "L") == ["UL", "LU"]
    @test assembly_products(system, "L", "L") == ["LL"]
    # Distinct operands can also yield duplicate products.
    @test assembly_products(system, "L", "LL") == ["LLL"]
    @test_throws ArgumentError assembly_products(system, "", "L")
    @test_throws ArgumentError assembly_products(system, "L", "X")
end

@testset "Configurable primitives and alphabets" begin
    blocks = ["UU", "LL", "UU"]
    system = DirectedStringSystem(blocks)
    @test building_blocks(system) == blocks # Neither sorted nor deduplicated.
    blocks[1] = "X"
    @test building_blocks(system) == ["UU", "LL", "UU"]
    copied = building_blocks(system)
    copied[2] = "X"
    @test building_blocks(system)[2] == "LL"
    @test is_valid_object(system, "L") # Valid does not mean primitive or reachable.
    @test !("L" in building_blocks(system))
    @test is_valid_object(system, "ULUL")
    @test !is_valid_object(system, "A")
    @test !verify(system, Construction([AssemblyStep(1, 2, "L")]))

    other = DirectedStringSystem(("αβ", "β"))
    @test is_valid_object(other, "βαα")
    @test !is_valid_object(other, "L")
    @test assembly_products(other, "α", "β") == ["αβ", "βα"]
    alphabet = ['A', 'B', 'C']
    explicit = DirectedStringSystem(["AB"]; alphabet)
    alphabet[1] = 'X'
    @test is_valid_object(explicit, "C")
    @test is_valid_object(explicit, "BA")
    @test building_blocks(explicit) == ["AB"]
    @test !is_valid_object(explicit, "X")
    @test !is_valid_object(explicit, "")
    @test is_valid_object(DirectedStringSystem(["L"]; alphabet="LU"), "U")
    @test_throws ArgumentError DirectedStringSystem(String[])
    @test_throws ArgumentError DirectedStringSystem([""])
    @test_throws ArgumentError DirectedStringSystem(["L", ""])
    @test_throws ArgumentError DirectedStringSystem([1])
    @test_throws ArgumentError DirectedStringSystem(["LU"]; alphabet="L")
    @test_throws ArgumentError DirectedStringSystem(["L"]; alphabet=["L"])
    @test_throws MethodError DirectedStringSystem(Set(["L", "U"]))

    original = DirectedStringSystem()
    reordered = DirectedStringSystem(["U", "L"])
    claim = Construction([AssemblyStep(1, 1, "LL")])
    @test verify(original, claim)
    @test !verify(reordered, claim) # Certificates are relative to primitive order.
    custom = DirectedStringSystem(["A", "B"]; rule=LeftOnly())
    @test assembly_products(custom, "A", "B") == ["AB"]
    @test !verify(custom, Construction([AssemblyStep(1, 2, "BA")]))
end

@testset "Composition rules restrict products" begin
    by_count = DirectedStringSystem(; rule=HigherLCount())
    by_proportion = DirectedStringSystem(; rule=HigherLProportion())
    for system in (by_count, by_proportion)
        @test assembly_products(system, "U", "L") == ["LU"]
        @test assembly_products(system, "L", "U") == ["LU"]
        @test assembly_products(system, "LU", "UL") == ["LUUL", "ULLU"]
        @test assembly_products(system, "L", "L") == ["LL"]
        @test assembly_products(system, "L", "LL") == ["LLL"]
        @test verify(system, Construction([AssemblyStep(2, 1, "LU")]))
        @test !verify(system, Construction([AssemblyStep(1, 2, "UL")]))
    end
    # More L's and a greater proportion of L's can choose opposite directions.
    @test assembly_products(by_count, "LLUUU", "L") == ["LLUUUL"]
    @test assembly_products(by_proportion, "LLUUU", "L") == ["LLLUUU"]
    @test assembly_products(by_count, "L", "LLUUU") == ["LLUUUL"]
    @test assembly_products(by_proportion, "L", "LLUUU") == ["LLLUUU"]
    @test assembly_products(by_count, "LU", "L") == ["LUL", "LLU"]
    @test assembly_products(by_proportion, "LU", "L") == ["LLU"]
    @test assembly_products(by_count, "LU", "LLUU") == ["LLUULU"]
    @test assembly_products(by_proportion, "LU", "LLUU") == ["LULLUU", "LLUULU"]
    @test assembly_products(by_proportion, "LLUU", "LU") == ["LLUULU", "LULLUU"]
    # Non-L characters, including Unicode, count as characters in the denominator.
    unicode = DirectedStringSystem(["L", "α"]; rule=HigherLProportion())
    @test assembly_products(unicode, "Lα", "LLαα") == ["LαLLαα", "LLααLα"]
    no_l = DirectedStringSystem(["A", "B"]; rule=HigherLCount())
    @test assembly_products(no_l, "A", "B") == ["AB", "BA"]
end

@testset "References preserve history and target ancestry" begin
    system = DirectedStringSystem()
    construction = Construction([
        AssemblyStep(1, 2, "LU"),   # Ref 3.
        AssemblyStep(2, 1, "LU"),   # Ref 4: equal object, different history.
        AssemblyStep(3, 3, "LULU"), # Ref 5: repeated parent.
        AssemblyStep(3, 4, "LULU"), # Ref 6: shared ancestors across targets.
        AssemblyStep(1, 1, "LL"),   # Ref 7: unrelated later step.
    ])
    @test verify(system, construction)
    @test reference_object(system, construction, 1) == "L"
    @test reference_object(system, construction, 3) == "LU"
    @test reference_object(system, construction, 4) == "LU"
    @test parent_references(system, construction, 1) == ()
    @test parent_references(system, construction, 3) == (1, 2)
    @test parent_references(system, construction, 4) == (2, 1)
    @test parent_references(system, construction, 5) == (3, 3)
    @test ancestor_steps(system, construction, 5) == [1, 3]
    @test ancestor_steps(system, construction, 6) == [1, 2, 4]
    @test ancestor_steps(system, construction, [5, 6]) == [1, 2, 3, 4]
    @test ancestor_steps(system, construction, [6, 1, 5, 6]) == [1, 2, 3, 4]
    @test ancestor_steps(system, construction, 3) == [1]
    @test ancestor_steps(system, construction, 1) == Int[]
    @test ancestor_steps(system, construction, [1, 2]) == Int[]
    @test ancestor_steps(system, construction, Int[]) == Int[]
    @test ancestor_steps(system, construction, 7) == [5]
    empty = Construction(AssemblyStep{String}[])
    @test ancestor_steps(system, empty, 2) == Int[]

    for ref in (0, -1, 8)
        @test_throws ArgumentError reference_object(system, construction, ref)
        @test_throws ArgumentError parent_references(system, construction, ref)
        @test_throws ArgumentError ancestor_steps(system, construction, ref)
    end
    @test_throws ArgumentError ancestor_steps(system, construction, [3, "4"])
    for parent in (0, -1, 3, 4)
        invalid = Construction([AssemblyStep(parent, 1, "LL")])
        @test !verify(system, invalid)
        @test_throws ArgumentError ancestor_steps(system, invalid, 3)
    end
    # Inspection of an earlier target does not depend on unrelated later claims.
    bad_tail = Construction([AssemblyStep(1, 2, "LU"), AssemblyStep(5, 1, "LUL")])
    @test !verify(system, bad_tail)
    @test ancestor_steps(system, bad_tail, 3) == [1]
    # Ancestry checks references, not rule membership.
    bad_product = Construction([AssemblyStep(1, 2, "LL")])
    @test ancestor_steps(system, bad_product, 3) == [1]
    @test !verify(system, bad_product)
end

@testset "Integer addition uses generic certificates" begin
    system = IntegerAdditionSystem()
    construction = Construction([
        AssemblyStep(1, 1, big(2)), # Ref 2.
        AssemblyStep(2, 2, big(4)), # Ref 3.
        AssemblyStep(3, 2, big(6)), # Ref 4.
    ])
    @test building_blocks(system) == [big(1)]
    @test verify(system, construction)
    @test verify(system, Construction(AssemblyStep{BigInt}[]))
    @test reference_object(system, construction, 4) == 6
    @test parent_references(system, construction, 2) == (1, 1)
    @test ancestor_steps(system, construction, [2, 4]) == [1, 2, 3]
    @test ancestor_steps(system, construction, 1) == Int[]
    @test assembly_products(system, 2, 3) == [big(5)]
    @test assembly_products(system, typemax(Int), 1) == [big(typemax(Int)) + 1]
    @test !is_valid_object(system, 0)
    @test !is_valid_object(system, "1")
    @test_throws ArgumentError assembly_products(system, 0, 1)
    @test !verify(system, Construction([AssemblyStep(1, 1, big(3))]))
    @test !verify(system, Construction([AssemblyStep(2, 1, big(2))]))
    @test !verify(system, Construction([AssemblyStep(1, 1, big(0))]))
end

@testset "Independent construction verification" begin
    system = DirectedStringSystem()
    @test verify(system, Construction(AssemblyStep{String}[]))
    @test verify(system, Construction([AssemblyStep(1, 2, "LU")]))
    @test verify(system, Construction([AssemblyStep(1, 2, "UL")]))
    # Reference 3 is LU. Reuse it within one step and in a later step;
    # building block 1 also remains available after its earlier use.
    construction = Construction([
        AssemblyStep(1, 2, "LU"),
        AssemblyStep(3, 3, "LULU"),
        AssemblyStep(3, 1, "LUL"),
        AssemblyStep(4, 5, "LULULUL"),
    ])
    @test verify(system, construction)
    @test length(construction.steps) == 4
    @test verify(system, construction) # Replay does not consume or mutate it.

    for step in (AssemblyStep(0, 2, "LU"),
                 AssemblyStep(-1, 2, "LU"),
                 AssemblyStep(1, 0, "LU"),
                 AssemblyStep(1, 3, "LU"), # Self reference.
                 AssemblyStep(4, 2, "LU"), # Forward reference.
                 AssemblyStep(1, 2, "LL"), # Valid object, forbidden product.
                 AssemblyStep(1, 2, "LX"),
                 AssemblyStep(1, 2, ""))
        @test !verify(system, Construction([step]))
    end
    @test !verify(system, Construction([
        AssemblyStep(1, 2, "LU"),
        AssemblyStep(3, 1, "LLU U"),
    ]))
    # An object is unavailable until its explicit producing step exists.
    @test !verify(system, Construction([AssemblyStep(3, 3, "LULU")]))
end
