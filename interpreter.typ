= Program Evaluation

The first major design decision to decide what kinds of programming languages we will consider. Throughout this project, we will only consider simply typed (total) functional languages without any advanced features (such as pattern matching, exceptions, type constructors, etc...).#footnote[Anyone unfamiliar with the basics of Lambda Calculus should see @lambda_glossary for some important definitions.] This is because their simplicity makes them much easier to define, implement, analyze, and because they share a common grammar, which allows us to enumerate programs much more easily. What this means is that a language's behaviour should defined solely by the builtin primitive constants it provides. As we will see later on, this limitation will actually turn out to be a powerful tool in defining our search space more precisely.

== Functional Terms

We define expressions in such a language as follows: 

```rust
pub type Thunk = Rc<RefCell<Term>>; // A pointer to a mutable term
pub type Value = Rc<dyn TermValue>; // A pointer to a value

pub enum Term {
    Val(Value), // A primitive value
    Var(Identifier), // A variable identifier
    Lam(Identifier, Rc<Term>), // A lambda abstraction 
    App(Thunk, Thunk), // An application of one term on another
    Ref(Thunk), // Transparent indirection to another term 
}
```

#let app = $circle.stroked.small$

The `Value` type stores a pointer to a value, whose type has been erased (similar to how Haskell erases all type information at runtime). The `Ref` variant is simply a transparent pointer to another term, which will be useful during term reduction. As an example, the $lambda$-term $lambda x."max"(x) (1)$ would be represented as follows (omitting pointers and `Ref`s, and denoting application by #app):

#import "@preview/cetz:0.3.4": canvas, draw, tree
#align(center)[
  #canvas({
    import draw: *
    
    set-style(content: (padding: .1))

    tree.tree(([$lambda x$], ([#app], ([#app], [max], [$x$]), [1])), spread: 1.3)

  })
]

We define the *size* of a term as the number of nodes in this tree. For example, the term in the figure above has size 6.

In order to simplify this syntax in our code, define a `term!` macro which parses these terms at compile-time. It allows us to write in a more familiar Haskell-style syntax, and insert variables and constants into terms:

```rust
// A pure lambda-term
let apply = term!(f x -> f x x);

// Inserting a term stored in a variable into a template.
let square = term!([apply] multiply); 

// Literals are parsed as values  
let two = term!((a b -> a) 2 "x");

// Brackets starting with a colon indicate a variables
// should be parsed as a value.
let two = 2;
let four = term!([square] [:two]);
```

== Functional Languages

As stated earlier, in their most basic form, our languages are determined by the primitives they offer, each of which will be annotated with a `Type`. Again, we will only consider simply-typed programs, meaning we do not allow any kind of polymorphism.

```rust
pub enum Type {
    Var(Identifier), // A base type
    Fun(Rc<Type>, Rc<Type>), // A function type
}
```

In order to evaluate a term, we will have to define an environment in which to run in. We do this by defining a `Language` trait (an interface, in other languages) with a method to construct the `Context` terms will be evaluated in. We also provide a `Builtin` type and a `builtin!` macro to simplify the definition of primitives, both of whose definitions we omit from this report. A simple example we will revisit several times is the language of polynomials with positive integer coefficients:

```rust
// Polynomials is a data structure with no fields
pub struct Polynomials;

impl Language for Polynomials {
  fn context(&self) -> Context {
    let plus = builtin!(
        N => N => N 
        |x, y| => Term::val(x.get::<i32>() + y.get::<i32>())
    );

    let mult = builtin!(
        N => N => N
        |x, y| => Term::val(x.get::<i32>() * y.get::<i32>())
    );

    // Constants, which don't take any arguments
    let one = builtin!(
        N
        | | => Term::val(1i32)
    );

    let zero = builtin!(
        N
        | | => Term::val(0i32)
    );

    //Mapping from Identifiers to builtins
    Context::new(&[
      ("plus", plus),
      ("mult", mult),
      ("one",  one ),
      ("zero", zero),
    ])
  }
}
```

The `Term::val` function converts its argument into a `Term` by converting it into a `Value`. The `Term::get` method casts a `Term::Val` into a given type (which can never fail if our program is well-typed). It's worth noting that these primitives are strict in all their arguments. We can get around this by reducing to a projection term instead of taking extra arguments:

```rust
// ifpos c t e = if (c) { t } { e }
// Lazy in `t' and `e' 
let ifpos = builtin!(
  Bool => N => N => N 
  |c| => if c.get::<bool>() {
    term!(t e -> t)
  } else {
    term!(t e -> e)
  }
)
```

== Term Reduction

The implementation we use is essentially the graph reduction technique described in _The Implementation of Functional Programming Lanugages_ @SLPJ. This allows for laziness and shared reduction and is performant enough for our purposes, but more sophisticated (even optimal) algorithms exist.

To evaluate a term, we reduce it until we reach a weak head normal form (WHNF). That is, either a lambda abstraction or a primitive function applied to too few arguments. Our reduction strategy is based on _spine reduction_. We traverse the term's leftmost nodes top-down until we reach the _head_ of the term (the first subterm which is not an application). If the head is an application of a $lambda$-abstraction to an argument, we perform a _template instantiation_ operation, substituting a reference to the argument in place of the parameter everwhere it appears in the body of the lambda term (this is where the `Ref` variant is useful). If the head is a variable, we look it up in our context, and (if it exists), check if it is applied to enough arguments to invoke its definition. If so, we evaluate all of its arguments (hence the strictness of primitives) and replace the subnode at the appropriate level with the result. We continue until we perform no more reductions. A simplified version of the interpreter's main code is shown below.

```rust
enum CollapsedSpine {
    // If spine is in weak head normal form
    Whnf,
    // A built-in function & a stack of arguments
    Exec(BuiltIn, Vec<Thunk>),
}

impl Context {
  // Caller function ignores output of collapse_spine
  pub fn evaluate(&self, term: &mut Term) {
    self.collapse_spine(&mut term, 0);
  }
  
  //The depth is the number of arguments along the spine, so far 
  pub fn collapse_spine(
    &self,
    term: &mut Term,
    depth: usize
  ) -> CollapsedSpine {
    match term {
      Ref(r) => self.collapse_spine(r, depth),
      Val(_) | Lam(_, _) => Whnf,
      Var(v) => match self.lookup(v) {
        // If head is a variable takes no arguments, once again,
        // replace it and continue,
        Some(builtin) if builtin.n_args == 0 => {
          *term = builtin.func(&[]);
          self.collapse_spine(term, depth)
        },
        // If we have enough arguments to apply this function,
        // we start building a stack of arguments.
        Some(builtin) if builtin.n_args <= depth {
          Exec(builtin, vec![])
        }
        // If we do not have enough arguments, we are in WHNF
        _ => Whnf,
      }
      App(l, r) => match self.collapse_spine(l, depth + 1) {
        Exec(builtin, mut args) => {
          args.push(r);
          //If we have enough arguments, apply the function 
          if args.len() == builtin.n_args {
            // The args will be in reverse order
            args.reverse();
            for arg in &mut args {
              self.evaluate(arg);
            }
            // Call function & continue
            *term = builtin.func(&args);
            return self.collapse_spine(term, depth);
          }
          // If we do not have enough arguments, keep pushing
          // onto the stack of parameters.
          Exec(builtin, args)
        } 
        // Template instantiation
        Whnf => if let Lam(arg, body) = l {
          *term = body.instantiate(arg, r);
          self.collapse_spine(term, depth)
        } else {
          Whnf
        }
      }
    }
  } 
}
```

#pagebreak()
