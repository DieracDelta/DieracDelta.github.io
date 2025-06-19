#import "../lib.typ": *
#show: schema.with("page")

// #show math.equation: it => {
//   let math-class(content) = html.elem("span", attrs: (class: "math-equation"), content)
//   math-class(html.frame(it))
// }

#title[Understanding Subtyping in Rust]
#date[2022-06-25]
#author[Justin Restivo]

= Expected background

This post to targets folks with Rust experience.

= Background: Categories and Functors

Contravariance and covariance are best understood with a healthy dose of category theory.

== Categories

The first step is to understand a category. Hand-waving formalism, a category can be understood as:

- A set of objects.
- A set of arrows between objects, called morphisms. For a morphism from object $a$ to object $b$ we define a morphism as $a -> b$.

At this point, this should feel very similar to a DAG. We also want to be able to traverse with morphisms. This introduces a binary operator, $compose$, to compose morphisms such that morphisms in a way that allows for both identity and associativity. The identity law states that every object $a$ has an arrow pointing to itself. We call this $a$'s identity morphism and denote it $a -> a$. Associativity means that morphisms associate together.

More formally (using $compose$ for composition), and assuming:

- $x, a, b, c$ are objects in a category, C
- $f eq.delta (a -> b)$
- $g eq.delta (b -> c)$
- $h eq.delta (c -> d)$

Our laws on composition become:
#let id = "id"

- if $f, g, h$ exist, then the morphisms $f compose (g compose h)$ and $(f compose g) compose h$ exist and are the same morphism.
- For every object $x$ in $C$, there exists an identity morphism `id_x` defined as $x -> x$ such that composing this identity morphism with any morphism either into or out of $x$ is that morphism. That is, for some object $a$ if morphism $a -> x$ exists then $(a -> x) compose id_x$ is $a -> x$. And, for some object $b$, if morphism $x -> b$ exists, then $id_x compose (x -> b)$ is $x -> b$.

== Functors

At a high level, a functor is a mapping between two categories. Denote these categories $A, B$. Then we have two surjective mappings: one from objects in category $A$ to objects in category $B$, and another mapping for morphisms in category $A$ to morphisms in category $B$. Note that surjective here means all objects and morphisms in $A$ are mapped.

== Covariant functors

With covariant functors, the morphism mappings must preserve identity and composition. Suppose we have two objects $a$ and $b$ in category $A$ that we map to objects $f a$ and $f b$ in category $B$. The identity preservation is done by forcing the $a -> a$ morphism in category $A$ to map to $f a -> f a$ in category $B$.

The composition property means that composition of morphisms done in category $A$ must be preserved in category $B$. E.g. if I start on object $a$, go through object $b$ to object $c$ all in category $A$, then I should be able to follow the mapped morphisms to go from $f a$ through $f b$ to $f c$ in category $B$.

Covariant functors preserve the direction of morphisms. Then suppose in category $A$ we have a morphism $a -> b$. This means the morphism in category $B$ will be $f a -> f b$ due to the composition preservation (compose $a -> b$ with identity on either $a$ or $b$).

== Contravariant functors

Contravariant functors are also a mapping, but they flip the requirements: identity is preserved but composition is reversed in the target category. So $a -> b$ is mapped to $f b -> f a$.

== Product category

A product category $P$ is defined to be a sort of "product" of categories $A$ and $B$. Specifically, an object in $P$ is defined for every two objects in $A$ and $B$. So, if $a'$ is defined in $A$ and $b'$ is defined in $B$, then $(a', b')$ must be an object in $P$. Morphisms in $P$ only exist if their respective morphisms exist in $A$ and $B$.

== Bifunctors

Bifunctors are functors defined over a product category.

= Subtyping

Across programming languages, one may encounter a subtyping operator `<:`. This binary operator when used on two "things" `a, b` as `a <: b` means `a` is a subtype of `b`. More intuitively, `'a <: 'b` means `'a` can be used everywhere `'b` is used. The examples in the #link("https://doc.rust-lang.org/nomicon/subtyping.html")[rust docs] give the example of animals. A dog is an animal because one may use a dog wherever one uses an animal.

What does "things" mean? That is, what are `a` and `b`? Typically in programming languages, subtyping is defined on the programming language's base kind. In Haskell, this is `Type`. But, Rust has two base kinds: `Type` and `Lifetime`. So, Rust may have `Type`s subtyping other `Type`s, and lifetimes subtyping other lifetimes.

== Rust Subtyping

With Rust types, the intuition (as made in the rustnomicon) is that of the `Cat` and `Dog` example. If type `Cat` subtypes type `Animal`, then `Animal` is more general than `Cat`, and we may use `Cat` wherever we use `Animal` since `Cat` *is* an animal. But, in Rust, there is no `Cat` or `Dog`. Instead, Rust only does subtyping on the same type constructor (though this may be generic).

Rust lifetimes have a similar idea to the `Cat` and `Animal` example. If `'long <: 'short` (where `'long` and `'short` are lifetimes), then we may use the variable with lifetime `'long` everywhere `'short` may be used. The intuition is since `'a` lives longer than `'b`, then we may use variables that live `'a` long everywhere variables with `'b` are used without worrying about them being freed.

A graphic diagram should explain this intuition:

```
'long 'short | time (increasing)
 |           |
 -------->   | start 'long
 |           |
 |           |
 |           |
 |     -->   | start 'short
 |     |     |
 |     |     |
 |     |     |
 |     -->   | end 'short
 |           |
 |           |
 |           |
 |           |
 |           |
 -------->   | end 'long
             |


```

Practically, `'static` subtypes *every* lifetime since it is defined to be the longest living lifetime (it lives for the entire program).

== Rust Subtyping Inference

Rust's subtyping inference rules begin with lifetimes. Rust infers the lifetime length and then lifetime subtyping relations. Then, Rust infers subtyping relations on Types.

The second way Rust is able to subtype is by using several specific rules over types based on their input lifetime parameters. For example, if `'static <: 'a`, then `&'static str <: &'a str`. Note this is just an example, and we haven't discussed *why* this is true. Now, consider the following chart:

| Functor | 'a | T | U |
|-----------------|:---------:|:-----------------:|:---------:|
| `&'a T ` | covariant | covariant | |
| `&'a mut T` | covariant | invariant | |
| `Box<T>` | | covariant | |
| `Vec<T>` | | covariant | |
| `UnsafeCell<T>` | | invariant | |
| `Cell<T>` | | invariant | |
| `fn(T) -> U` | | contravariant | covariant |
| `*const T` | | covariant | |
| `*mut T` | | invariant | |

= Covariant example

Let's build up intuition for these inference rules via a few examples, starting with `&'a T`. `&` is a type constructor that takes in two arguments: a lifetime and a type. This may be thought of as a bifunctor. The category the bifunctor maps from is a product category. The two categories used to create this product category are essentially:

$ C_{"lifetimes"} eq.delta "rust lifetimes as objects with morphisms defined as subtypes" $

$ C_{"types"} eq.delta "rust types as objects with morphisms defined as subtypes}" $

Then, the product category we're mapping from is then $C_{"lifetimes"} times C_{"types"}$, and the category we map to is $C_{"types"}$. The implication is: `'a <: ' b, T <: U` $arrow.r.double$ `&'a T <: &'b U` exactly because `('a, T)` and `('b, U)` are objects in the input category $C_{"lifetimes"} times C_{"types"}$. Since $'a -> 'b$ and $T -> U$ in the indiviual categories, `('a, T)` $->$ `('b, U)` must be a morphism in the product category by definition. And this maps to `& 'a T` $->$ `&'b U` in the output $C_{"types"}$. The map is a subtyping relationship.

Intuitively, this should also make sense: `&'a T` can be used everywhere `&'b U` is used for two reasons. First, `T` can be used everywhere `U` is used. Secondly, `'a` (which is the lifetime of `&`) lives longer than `'b` so there are no worries about use after free.

= Contravariant Example

There are other covariant examples with functors (and bifunctors) that work very similarly to the prior example. There is, however, one contravariant example: function types. In this case, we have that: `S <: T, U <: V => fn(T) -> U <: fn(S) -> V`

This construction should make sense from a category point of view. The input category is the product category $C_{"types"}^{"Op"}} times C_{"types"}$ and the bifunctor maps to $C_{"types"}$. The difference here is the usage of the opposite cateogry. This category takes the input category and flips the direction of all its morphisms. This essentially means that the mapping is contravariant in the first argument. So for objects $(a, b), (c, d)$, morphisms $f (a, b) -> f (c, d)$ only exist in the output category when morphisms $c -> a$ (notice this is flipped!) and $b -> d$ exist in the input to the product category.

For simplicity, denote:

$ f eq.delta "fn"(T) -> U $
$ g eq.delta "fn"(S) -> V $

Then `f <: g`.

I'm simplifying this but, the intuition for this subtyping relation can be thought of as enforcing lifetimes. If we want to be able to use `f` everywhere that we can use `g`, then the arguments to `f` cannot be used as long as long as the arguments to `g`. And the returned type must live longer than that of `g` so we can use it as we might use `g`'s output. All this is doing is enforcing that with lifetimes.

= Invariant

Invariant in this case simply means with any sort of functor we define (covariant or contravariant), there is no morphism mapping that makes sense. These are like `Cat` and `Dog` -- a subtyping relationship does not make sense.

= Struct Type Example

Let's also consider a simplified example from #link("https://doc.rust-lang.org/reference/subtyping.html")[the rust reference]

```rust
use std::cell::UnsafeCell;
struct Variance<'a, T, U: 'a> {
    x: &'a U,               // This makes `Variance` covariant in 'a, and would
                            // make it covariant in U, but U is used later
    y: *const T,            // Covariant in T
}
```

This is defining a product category: $C_{"lifetime"} times C_{"type"} times C_{"type"}$. The subtyping rules from above apply to the innards of the struct and therefore the struct itself. We simply have morphisms on the output category when both functors map.
