using AssemblyTheory

for (system, target) in ((IntegerAdditionSystem(), big(7)),
                         (DirectedStringSystem(), "LLULL"))
    println(repr(target), ": ", assembly_index(system, target))
end
