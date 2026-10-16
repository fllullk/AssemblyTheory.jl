"""An assembly system whose objects have type `T`. See the interface functions below."""
abstract type AbstractAssemblySystem{T} end

"""Return the ordered building blocks of a system, available without assembly steps."""
function building_blocks end

"""Return the distinct allowed products of joining two valid objects."""
function assembly_products end

"""Return whether an object satisfies the system's validity constraints."""
function is_valid_object end

"""System-specific object equality; defaults to `==`."""
object_equal(::AbstractAssemblySystem, a, b) = a == b

"""A string rule implements `assembly_products(rule, a, b)` for valid operands."""
abstract type AbstractStringRule end

"""Permit both concatenation orders, removing duplicate products."""
struct UnrestrictedConcatenation <: AbstractStringRule end

"""Put the operand with more `L` characters on the left; allow both orders on ties."""
struct HigherLCount <: AbstractStringRule end

"""
Put the operand with higher `L` count / character length on the left.
Compare exactly, allowing both distinct orders on ties. This restricts products;
it does not assign sampling probabilities.
"""
struct HigherLProportion <: AbstractStringRule end

function assembly_products(::UnrestrictedConcatenation, a::AbstractString, b::AbstractString)
    forward, backward = string(a, b), string(b, a)
    return forward == backward ? [forward] : [forward, backward]
end

function _ordered_products(a, b, score_a, score_b)
    score_a > score_b && return [string(a, b)]
    score_a < score_b && return [string(b, a)]
    return assembly_products(UnrestrictedConcatenation(), a, b)
end

assembly_products(::HigherLCount, a::AbstractString, b::AbstractString) =
    _ordered_products(a, b, count(==('L'), a), count(==('L'), b))

function assembly_products(::HigherLProportion, a::AbstractString, b::AbstractString)
    # Arbitrary-precision cross products avoid floating-point and integer overflow.
    return _ordered_products(a, b, big(count(==('L'), a)) * length(b),
                                  big(count(==('L'), b)) * length(a))
end

"""
    DirectedStringSystem(blocks=["L", "U"]; alphabet=nothing,
                         rule=UnrestrictedConcatenation())

Configure directed strings using a nonempty vector or tuple of nonempty string
building blocks. Preserve their exact order and duplicates: references depend
on this order. Configuration is copied into immutable tuples.

By default, derive the alphabet from characters occurring in the blocks. An
explicit iterable of `Char` values (or a string) may enlarge the alphabet, but
must contain every block character. Valid objects are all nonempty words over
that alphabet, whether or not available as primitives or constructible.
Equality is exact character equality; reversal is not an equivalence.
"""
struct DirectedStringSystem{R<:AbstractStringRule} <: AbstractAssemblySystem{String}
    blocks::Tuple{Vararg{String}}
    alphabet::Tuple{Vararg{Char}}
    rule::R

    function DirectedStringSystem(blocks::Union{AbstractVector,Tuple}=["L", "U"];
                                  alphabet=nothing, rule::AbstractStringRule=UnrestrictedConcatenation())
        !isempty(blocks) && all(b -> b isa AbstractString && !isempty(b), blocks) ||
            throw(ArgumentError("provide a nonempty ordered collection of nonempty strings"))
        saved_blocks = Tuple(String(b) for b in blocks)
        chars = alphabet === nothing ? collect(Iterators.flatten(saved_blocks)) : collect(alphabet)
        all(c -> c isa Char, chars) || throw(ArgumentError("alphabet must contain characters"))
        saved_alphabet = Tuple(unique(chars))
        all(b -> all(c -> c in saved_alphabet, b), saved_blocks) ||
            throw(ArgumentError("alphabet must contain every building-block character"))
        return new{typeof(rule)}(saved_blocks, saved_alphabet, rule)
    end
end

building_blocks(system::DirectedStringSystem) = collect(system.blocks)

is_valid_object(::DirectedStringSystem, ::Any) = false
is_valid_object(system::DirectedStringSystem, s::AbstractString) =
    !isempty(s) && all(c -> c in system.alphabet, s)

function assembly_products(system::DirectedStringSystem, a::AbstractString, b::AbstractString)
    is_valid_object(system, a) && is_valid_object(system, b) ||
        throw(ArgumentError("operands must be nonempty words over the system alphabet"))
    return assembly_products(system.rule, a, b)
end

"""
    IntegerAdditionSystem()

Minimal positive-`BigInt` system with primitive `1` and binary addition.
Demonstrates the generic interface without addition-chain search. Arbitrary
precision avoids overflow; use `big` products in its construction certificates.
"""
struct IntegerAdditionSystem <: AbstractAssemblySystem{BigInt} end

building_blocks(::IntegerAdditionSystem) = [big(1)]
is_valid_object(::IntegerAdditionSystem, ::Any) = false
is_valid_object(::IntegerAdditionSystem, n::Integer) = n > 0

function assembly_products(system::IntegerAdditionSystem, a::Integer, b::Integer)
    is_valid_object(system, a) && is_valid_object(system, b) ||
        throw(ArgumentError("operands must be positive integers"))
    return [big(a) + big(b)]
end
