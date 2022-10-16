---
author:
  name: "Justin Restivo"
date: 2022-10-09
title: "Faking subtyping in Rust"
---

# Motivating the Problem

In short, we have no trait subtyping relationship. It would be great if this were possible. But alas, Rust doesn't allow for this (yet!). This post is aimed at working around this.

In Rust, suppose we have a lot of generics, with arbitrary constraints. For example, suppose we wish to build many types of animals. Each animal has `Ears`, `Mouth`, `Legs`, and `Lungs`. Each of these implement some traits. The normal ones like `Clone`, as well as `Send + Sync` to send between threads.

The first pass stab at this might look like:

```rust

pub trait Fluffy {};
pub trait Taste {};
pub trait Legs {};
pub trait Lungs {};



pub trait Animal<Ears, Mouth, Legs, Lungs>
where
  Ears: Clone + Send + Sync + Fluffy,
  Mouth: Clone + Send + Sync + Taste,
  Legs: Clone + Send + Sync + Fast,
  Lungs: Clone + Send + Sync + Breathe,
{}

```

Suppose we wish to implement this and type constrain it. Any impl block is going require this awkward set of type constraints.

```rust
impl<ANIMAL, EARS, MOUTH, LEGS, LUNGS>
where
  EARS: Clone + Send + Sync + Fluffy,
  MOUTH: Clone + Send + Sync + Taste,
  LEGS: Clone + Send + Sync + Fast,
  LUNGS: Clone + Send + Sync + Breathe,
  ANIMAL: Animal<Ears, Mouth, Legs, Lungs>
{

}
```

This is gross. It doesn't scale. It's very easy to mis-order the generics. Luckily, Rust has a way around this: associated types. We instead have something like:

```rust
pub trait Animal : Clone + Send + Sync {
  type Ears: Clone + Send + Sync + Fluffy;
  type Mouth: Clone + Send + Sync + Taste;
  type Legs: Clone + Send + Sync + Fast;
  type Lungs: Clone + Send + Sync + Breathe;
}
```

Then, our impl block looks like:

```rust
impl<ANIMAL: Animal>
{

}
```

And, we can have an implementation for an arbitrary struct:

```rust
pub struct AnimalImpl<Ears, Mouth, Legs, Lungs>{
  _pd_0: PhantomData<Ears>,
  _pd_1: PhantomData<Mouth>,
  _pd_2: PhantomData<Legs>,
  _pd_3: PhantomData<Lungs>,
}

impl<EARS, MOUTH, LEGS, LUNGS> Animal for AnimalImpl<EARS, MOUTH, LEGS, LUNGS>
where
  EARS: Clone + Send + Sync + Fluffy,
  MOUTH: Clone + Send + Sync + Taste,
  LEGS: Clone + Send + Sync + Fast,
  LUNGS: Clone + Send + Sync + Breathe,
{
  type Ears = EARS;
  type Mouth = MOUTH;
  type Legs = LEGS;
  type Lungs = LUNGS;
}
```

Unfortunately we have to awkwardly copy type constraints. But still, this is much cleaner, since our impl blocks will only be generic over `Animal`. It scales with the number of generics quite nicely.

# The Problem

This is all great until we want to build off this `Animal` trait while avoding having to copy around type constraints. Our very explicit goal is to keep all type constraints in the same place and repeated as few times as possible.

Suppose we wish to express types associated with a `Dinosaur`. Our `Dinosaur` is an animal, but we have additional requirements on its associated types. Its associated types must all must implement `Prehistoric`. A first attempt at this using associated types might look like:

```rust
pub trait Prehistoric {}

pub trait Dinosaur : Clone + Send + Sync {
  type Ears: Clone + Send + Sync + Fluffy + Prehistoric;
  type Mouth: Clone + Send + Sync + Taste + Prehistoric;
  type Legs: Clone + Send + Sync + Fast + Prehistoric;
  type Lungs: Clone + Send + Sync + Breathe + Prehistoric;
}
```

This works great! Except...we are now copying over all the type constraints from `Animal` into our `Dinosaur` trait. We can refactor out traits a bit:

```rust
pub trait AnimalPart: Clone + Send + Sync

pub trait AnimalEars: AnimalPart + Fluffy;
pub trait AnimalMouth: AnimalPart + Taste;
pub trait AnimalLegs: AnimalPart + Fast;
pub trait AnimalLungs: AnimalPart + Breathe;

pub trait Animal
{
  type Ears: AnimalEars;
  type Mouth: AnimalMouth;
  type Legs: AnimalLegs;
  type Lungs: AnimalLungs;
}

pub trait Dinosaur {
  type Ears: AnimalEars + Prehistoric;
  type Mouth: AnimalMouth + Prehistoric;
  type Legs: AnimalLegs + Prehistoric;
  type Lungs: AnimalLungs + Prehistoric;
}
```

This is almost what we want. Except, we really would like `Dinosaur` to implement `Animal`. Suppose `Animal` has an associated function `pub fn do_animal_things()` that we would like to call. Then we could have `Dinosaur` implement `Animal`:



```rust
pub trait Animal
{
  type Ears: AnimalEars;
  type Mouth: AnimalMouth;
  type Legs: AnimalLegs;
  type Lungs: AnimalLungs;

  pub fn do_animal_things();
}

pub trait Dinosaur {
  type Ears: AnimalEars + Prehistoric;
  type Mouth: AnimalMouth + Prehistoric;
  type Legs: AnimalLegs + Prehistoric;
  type Lungs: AnimalLungs + Prehistoric;
}
```


But how do we force the associated types on `Animal` to match those on `Dinosaur`? What if `Animal` has requirements not expressed in `Dinosaur`? We really want to force `Dinosaur` to implement `Animal`. A naive attempt to do this:


```rust
pub trait Dinosaur : Animal<Ears = Self::Ears, Mouth = Self::Mouth, Legs = Self::Legs, Lungs = Self::Lungs>{
  type Ears: AnimalEars + Prehistoric;
  type Mouth: AnimalMouth + Prehistoric;
  type Legs: AnimalLegs + Prehistoric;
  type Lungs: AnimalLungs + Prehistoric;
}
```

But alas! We end up with an error:

```
cycle detected when computing the super traits of `Dinosaur` with associated type name `Ears`
```

Now what?

# The Solution

The best way I could come up to do this is to add another associated type:

```rust
pub trait Dinosaur {
  type Ears: AnimalEars + Prehistoric;
  type Mouth: AnimalMouth + Prehistoric;
  type Legs: AnimalLegs + Prehistoric;
  type Lungs: AnimalLungs + Prehistoric;

  type Animal: Animal<Ears = Self::Ears, Mouth = Self::Mouth, Legs = Self::Legs, Lungs = Self::Lungs>
}
```

This is annoying because another associated type has been added. But then, initialization is easy:


```rust
impl<EARS, MOUTH, LEGS, LUNGS> Animal for AnimalImpl<EARS, MOUTH, LEGS, LUNGS>
where
  EARS: AnimalEars,
  MOUTH: AnimalMouth,
  LEGS: AnimalLegs,
  LUNGS: AnimalLungs,
{
  type Ears = EARS;
  type Mouth = MOUTH;
  type Legs = LEGS;
  type Lungs = LUNGS;

  pub fn do_animal_things();
}

impl<EARS, MOUTH, LEGS, LUNGS> Dinosaur for AnimalImpl<EARS, MOUTH, LEGS, LUNGS>
where
  EARS: AnimalEars + Prehistoric,
  MOUTH: AnimalMouth + Prehistoric,
  LEGS: AnimalLegs + Prehistoric,
  LUNGS: AnimalLungs + Prehistoric,
{
  type Ears = EARS;
  type Mouth = MOUTH;
  type Legs = LEGS;
  type Lungs = LUNGS;

  type Animal = Self;
}

```

I don't see a cleaner way to do this (if you do, let me know!). But, this surely is cleaner than restating type constraints everywhere as one might do if `Dinosaur` did not implement `Animal`. Or if we were using generics instead of associated types for both `Dinosaur` and `Animal`.
