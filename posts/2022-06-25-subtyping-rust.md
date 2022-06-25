---
author:
  name: "Justin Restivo"
date: 2022-05-24
title: "Understanding Subtyping in Rust"
---

# Expected background

This post to targets folks with rust experience.

# Background: Categories and Functors

Contravariance and covariance are best understood with a healthy dose of category theory.

## Categories

The first step is to understand a category. Hand-waving formalism, a category can be understood as:

- A set of objects.
- A set of arrows between objects, called morphisms. For a morphism from object $a$ to object $b$ we define a morphism as $a \rightarrow b$.

At this point, this should feel very similar to a DAG. We also want to be able to traverse with morphisms. This introduces a binary operator, $\cdot$, to compose morphisms such that morphisms in a way that preserves identity and associativity. There are laws for identity and associativity. The identity law states that every object $a$ has an arrow pointing to itself. We call this $a$'s identity morphism and denote it $ a \rightarrow a$.

## Functors

At a high level, a functor is a mapping between two categories (for example categories $A$ and $B$). This means two surjective mappings: one from objects in category $A$ to objects in category $B$, and another mapping for morphisms in category $A$ to morphisms in category $B$. Note that surjective here means all objects and morphisms in $A$ are mapped.

## Covariant functors

With covariant functors, the morphism mappings must preserve identity and composition. Suppose we have two objects $a$ and $b$ in category $A$ that we map to objects $f a$ and $f b$ in category $B$. The identity preservation is done by forcing the $a \rightarrow a$ morphism in category $A$ to map to $f a \rightarrow f a$ in category $B$.

The composition property simply means that composition of morphisms done in category $A$ must be preserved in category $B$. E.g. if I start on object $a$, go through object $b$ to object $c$ all in category $A$, then I should be able to follow the mapped morphisms to go from $f a$ through $f b$ to $f c$ in category $B$.

Covariant functors preserve the direction of morphisms. Then suppose in category $A$ we have a morphism $a \rightarrow b$. This means the morphism in category $B$ will be $f a \rightarrow f b$ due to the composition preservation (compose $a \rightarrow b$ with identity on either $a$ or $b$).

## Contravariant functors

Contravariant functors are also a mapping, but they flip the requirements: identity is preserved but composition is reversed in the target category. So $a \rightarrow b$ is mapped to $f b \rightarrow f a$.

## Product category

A product category $P$ is defined to be a sort of "product" of categories $A$ and $B$. Specifically, an object in $P$ is defined for every two objects in $A$ and $B$. So, if $a'$ is defined in $A$ and $b'$ is defined in $B$, then $(a', b')$ must be an object in $P$. Morphisms in $P$ only exist if their respective morphisms exist in $A$ and $B$.

## Bifunctors

Bifunctors are just functors defined over a product category.

# Subtyping

Rust lifetimes define a subtyping relationship `<:`. Intuitively, `'a <: 'b` means `'a` can be used everywhere `'b` is used. The examples in the [rust docs](https://doc.rust-lang.org/nomicon/subtyping.html) give the example of animals. A dog is an animal because one may use a dog wherever one uses an animal. In Rust, subtyping is done in two ways. First, with rust lifetimes (a subset of Rust types), a similar parallel may be made to the `Cat` and `Dog` example. If `'a <: 'b`, then we may use the variable with lifetime `'a` everywhere `'b` may be used. The intuition is: since `'a` lives longer than `'b`, then we may use variables that live `'a` long everywhere variables with `'b` are used without worrying about them being freed.

The second way Rust is able to subtype is by using several specific rules over types based on their input lifetime parameters. For example, if `'static <: 'a`, then `&'static str <: &'a str`. Note this is just an example, and we haven't discussed *why* this is true. Now, consider the following chart:


|  Functor        |     'a    |         T         |     U     |
|-----------------|:---------:|:-----------------:|:---------:|
| `&'a T `        | covariant | covariant         |           |
| `&'a mut T`     | covariant | invariant         |           |
| `Box<T>`        |           | covariant         |           |
| `Vec<T>`        |           | covariant         |           |
| `UnsafeCell<T>` |           | invariant         |           |
| `Cell<T>`       |           | invariant         |           |
| `fn(T) -> U`    |           | contravariant     | covariant |
| `*const T`      |           | covariant         |           |
| `*mut T`        |           | invariant         |           |


# Covariant example

Let's build up intuition via a few examples, starting with `&'a T`. `&` is a type constructor that takes in two arguments: a lifetime and a type. This may be thought of as a bifunctor. The category the bifunctor maps from is a product category. The two categories used to create this product category are essentially:

$C_{lifetimes} \triangleq \text{rust lifetimes as objects with morphisms defined as subtypes}$

$C_{types} \triangleq \text{rust types as objects with morphisms defined as subtypes}$

Then, the product category we're mapping from is then $C_{lifetimes} \times C_{types}$, and the category we map to is $C_{types}$. The implication is: `'a <: ' b, T <: U` $\implies$ `&'a T <: &'b U` exactly because `('a, T)` and `('b, U)` are objects in the input category $C_{lifetimes} \times C_{types}$. Since $'a \rightarrow 'b$ and $T \rightarrow U$ in the indiviual categories, `('a, T)` $\rightarrow$ `('b, U)` must be a morphism in the product category by definition. And this maps to `& 'a T` $\rightarrow$ `&'b U` in the output $C_{types}$. The map is a subtyping relationship.

Intuitively, this should also make sense: `&'a T` can be used everywhere `&'b U` is used for two reasons. First, `T` can be used everywhere `U` is used. Secondly, `'a` (which is the lifetime of `&`) lives longer than `'b` so there are no worries about use after free.

# Contravariant Example

There are other covariant examples with functors (and bifunctors) that work very similarly to the prior example. There is, however, one contravariant example: function types. In this case, we have that: `S <: T, U <: V => fn(T) -> U <: fn(S) -> V`

This construction should make sense from a category point of view. The input category is the product category $C_{types}^{\text{Op}} \times C_{types}$ and the bifunctor maps to $C_{types}$.  The difference here is the usage of the opposite cateogry. This category takes the input category and flips the direction of all its morphisms. This essentially means that the mapping is contravariant in the first argument. So for objects $(a, b), (c, d)$, morphisms $f (a, b) \rightarrow f (c, d) $ only exist in the output category when morphisms $c \rightarrow a$ (notice this is flipped!) and $b \rightarrow d$ exist in the input to the product category.

For simplicity, denote $f \triangleq fn(T) \rightarrow U$, $g \triangleq fn(S) \rightarrow V$. Then `f <: g`.

I'm simplifying this but, the intuition for this subtyping relation can be thought of as enforcing lifetimes. If we want to be able to use `f` everywhere that we can use `g`, then the arguments to `f` cannot be used as long as long as the arguments to `g`. And the returned type must live longer than that of `g` so we can use it as we might use `g`'s output. All this is doing is enforcing that with lifetimes.

# Invariant

Invariant in this case simply means with any sort of functor we define (covariant or contravariant), there is no morphism mapping that makes sense.

# Struct Type Example

Let's also consider a simplified example from [the rust reference](https://doc.rust-lang.org/reference/subtyping.html)

```rust
use std::cell::UnsafeCell;
struct Variance<'a, T, U: 'a> {
    x: &'a U,               // This makes `Variance` covariant in 'a, and would
                            // make it covariant in U, but U is used later
    y: *const T,            // Covariant in T
}
```

This is defining a product category: $C_{lifetime} \times C_{type} \times C_{type}$. The subtyping rules from above apply to the innards of the struct and therefore the struct itself. We simply have morphisms on the output category when both functors map.
