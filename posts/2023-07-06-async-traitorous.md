---
author:
  name: "Justin Restivo"
date: 2023-07-06
title: "The Async Trait-or and the Case for BoxSyncFuture"
---

# A Tale of Poor Ergonomics

Our story begins with poor ergonomics. We don't have currying in Rust. For example, in Haskell I can do:

```haskell
ghci> let addOne = (+ 1)
ghci> addOne 5
6
```

This is a function application. We apply `+` to one and get back a function that adds one to its input.

If we wish to do this in Rust, we can try first with a closure:

```rust
let add_one = |x| {
    x + 1
}
```

This is great! ...Until we need to store a function in a struct. We can't! The closure type is unique, and we can't represent it in Rust code. What's the work around? Trait objects! `Fn|FnMut|FnOnce` are traits that closures implement. So, how do we use this to represent functions at compile time? Sadly, we can't yet. The proposal use `impl` in types is still a WIP (TODO link). Ah, but instead we may use traits at runtime to solve our problem. We can cast our closure into a boxed trait object and pass that around!


```rust
use std::ops::{Add, Deref};

pub struct AddSomething<T: Add>(Box<dyn Fn(T) -> T>);

// trickiness to make `add_one` callable by
// getting the compiler to automatically dereference
// the type
impl<T: Add> Deref for AddSomething<T> {
    type Target = dyn Fn(T) -> T;

    fn deref(&self) -> &Self::Target {
        &*self.0
    }
}

pub fn main() {
    let add_one = AddSomething(Box::new(|i| { i + 1}));

    println!("add 1 to 5 is {}", add_one(5));
}
```

Alas, this is…not particularly great. It's hard to read, verbose to write, and generally annoying to maneuver.

# The Woes of Async

Let's increase the complexity! What if we want to have our function be async? Let's say we're returning a future that sleeps for a period of time. How do we do this? Well, first we need to pull in an async executor. Let's pull in tokio. A straw man attempt might be as follows:

```rust
#[tokio::main]
async fn main() {

    let f = async |x| {
        tokio::time::sleep(x).await;
    }
}

```

Sadly, we get an error:

```
error[E0658]: async closures are unstable
```

So, now what? Is there a way around this? Well, we can take inspiration from the `async-trait` crate and manually make our function async. Consider the following two functions:

```rust
async fn example_1() {}

use std::pin::Pin;
use std::future::Future;
fn example_2() -> Pin<Box<dyn Future<Output = ()> + Send + Sync>>{
    Box::pin(async { () })

}
```

These functions subtly different. `example_1` returns an `impl Future`, so the type will be known at compile time, whereas `example_2` boxes and pins the future, so its type will only be known at run time. We need this to be able to represent the type in other type definitions.

And, note the trait bounds. The output of `example_2` will be `Send` and `Sync` iff it is possible (e.g., if the future itself is `Sync` and `Send`, `Pin<Box<...>>` will be `Send` and `Sync`). This is useful because now, both the returned future and references to this future can be passed between threads.

Note: `example_2`'s type signature is particularly bad. The `future`'s crate has two type aliases to make this easier:

```rust
type BoxFuture<'a, T> =  Pin<Box<dyn Future<Output = T> + Send + 'a>>
type BoxLocalFuture<'a, T> = Pin<Box<dyn Future<Output = T> + 'a>>

```

Note that in the `BoxLocalFuture` case, the `Send` bound is missing, so the future cannot be sent between threads. Both types don't add `Sync`. This makes sense, as some futures are not `Sync`, but this will definitely bite us later on.

To make our function async, we need to use a `BoxFuture`:

```rust
use futures::future::BoxFuture;
use std::sync::Arc;
use std::ops::Deref;
use std::time::Duration;
use futures::FutureExt;

// millis + secs
#[derive(Clone)]
// arc is a bit more ergonomic for async code than Box is
pub struct GenTimer(Arc<dyn Fn(u64, u32) -> BoxFuture<'static, ()>>);

impl Deref for GenTimer {
    type Target = dyn Fn(u64, u32) -> BoxFuture<'static, ()>;

    fn deref(&self) -> &Self::Target {
        &*self.0
    }
}

#[tokio::main]
async fn main() {
    let gen_timer =
        GenTimer(Arc::new(|secs, millis| {
            async move {
                tokio::time::sleep(Duration::new(secs, millis)).await
            }
            .boxed() // NOTE using `boxed` from `futures::FutureExt` to box and pin up the future.
        }));

    gen_timer(1, 1).await;

    println!("completed the timer!");
}
```

Cool, this works!

# Spam Sync

Suppose we want to send our timer generating function to a different task. Something like:

```rust
#[tokio::main]
async fn main() {
    let gen_timer =
        GenTimer(Arc::new(|secs, millis| {
            async move {
                tokio::time::sleep(Duration::new(secs, millis)).await
            }
            .boxed() // NOTE using `boxed` from `futures::FutureExt` to box and pin up the future.
        }));

    tokio::task::spawn(
        async move {
            gen_timer(1, 1).await;
            println!("completed the timer!");
        }
    );
}

```

We get the error:
```
error: future cannot be sent between threads safely
   --> src/main.rs:30:9
    |
30  | /         async move {
31  | |             gen_timer(1, 1).await;
32  | |         }
    | |_________^ future created by async block is not `Send`
    |
    = help: the trait `Sync` is not implemented for `(dyn Fn(u64, u32) -> Pin<Box<(dyn futures::Future<Output = ()> + std::marker::Send + 'static)>> + 'static)`
note: captured value is not `Send`
   --> src/main.rs:31:13
    |
31  |             gen_timer(1, 1).await;
    |             ^^^^^^^^^ has type `GenTimer` which is not `Send`
note: required by a bound in `tokio::spawn`
   --> /playground/.cargo/registry/src/index.crates.io-6f17d22bba15001f/tokio-1.29.0/src/task/spawn.rs:166:21
    |
166 |         T: Future + Send + 'static,
    |                     ^^^^ required by this bound in `spawn`

error: future cannot be sent between threads safely
   --> src/main.rs:30:9
    |
30  | /         async move {
31  | |             gen_timer(1, 1).await;
32  | |         }
    | |_________^ future created by async block is not `Send`

```

We need the function contained in `GenTimer` to be guaranteed to implement `Sync` so that we can pass around the pointer to the function (that is, the `Arc<dyn...>`. To do this, the future returned by the function must also be `Sync`. Let's spam Sync:

![](../images/sync_meme.png)

# The Betrayal

Consider the following example, but inside our future we also call an async function defined in a trait.


