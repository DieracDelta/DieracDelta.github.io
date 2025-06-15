#import "../lib.typ": *
#show: schema.with("page")

#title[Programming Paradigms and Polymorphism]
#date[2022-10-09]
#author[Justin Restivo]

= Polymorphism

==

= Higher Kinded Types

= Higher Ranked Polymorphism

All types are implicitly qualified. A good explanation for this lives #link("https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/rank_polymorphism.html")[here]. In haskell syntax:

```haskell
-- this is implicitly adding a universal qualifier
f :: a -> a -> b
-- the qualifier:
f :: forall a b. a -> a -> b
```

Higher ranked polymorphism is simply allowing us to accept arguments and return polymorphic functions. For example, rank 2 polymorphism allows us to return functions containing a forall.

```haskell
f :: (forall a. a) -> (forall b. b)
```

The level of nested qualification determines the "ranked"-ness of the polymorphism. For example, the following function would be of rank 3:

```haskell
f :: (Int -> (forall a. a)) -> Int
```

TODO transformers/why this is useful

= SystemF
