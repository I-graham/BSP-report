= Semantic Analysis

While the enumerator may be sufficient to find simple programs in small program spaces, we can massively shrink the program space by performing some semantic analysis. This feature is optional and language-specific. We can do this by building up a 'Canonical' representation of the semantics of each subexpression in any given program. This way, we can enumerate only programs with distinct semantics. This also speeds up the enumeration, since we can also avoid search paths which repeat the same semantics more than once. For example, we might want to detect that the programs `(+) x y` and `(+) y x` are the same, and therefore our enumerator should output one of these, but not both. 

== Semantic Analysis Interface

Since these semantics are language-specific, we define a `Language` trait (or interface) with methods defining the language's `Context` and semantics:

```rust
pub trait Language: Sized + Clone + Debug {
  // The type of the semantic representation of programs of this language
  type Semantics: Semantics + Sized;

  fn context(&self) -> Context; // The primitives this Language provides

  // Semantics of a variable (with type annotations)
  fn svar(&self, var: Identifier, ty: &Type) -> Analysis<Self>;
  fn slam( // Semantics of a lambda abstraction
      &self,
      ident: Identifier, // Variable being abstracted over
      body: Analysis<Self>, // Semantics of function body
      ty: &Type, // The type of the lambda abstraction
  ) -> Analysis<Self>;
  fn sapp( // Semantics of an application
      &self,
      fun: Analysis<Self>, // The function being applied
      arg: Analysis<Self>, // The argument to the function
      ty: &Type, // The type of the application
  ) -> Analysis<Self>;
}

pub enum Analysis<L: Language>
where
    L::Semantics: Semantics,
{
    Malformed, // Reject Term entirely (i.e, unnecessarily complex)
    Unique,    // Allow, but do not construct canonical form
    Canonical(L::Semantics), // Group into equivalence class by canonical form
}
```

As we build up the program, we also build up its semantics using the semantics of its subterms. #footnote[We are defining a _fold_ (or catamorphism) from programs of a certain language (with type annotations) to their canonical semantic representations.] Since the semantics of each subterm depend only on the semantics of its own subterms, we can ensure that any two terms with the same semantics (and the same type) are interchangeable, and we don't lose any expressivity by not repeating terms with the same semantics. #footnote[This is based on the idea of _Contextual Equivalence_: If two terms $S$, $T$, have the same semantics, then for any context $C[X]$, $C[S]$ should have the same semantics as $C[T]$. Essentially, we are forbidding introspection.] Since we shouldn't expect to be able to able to perfectly analyze every program, we include the `Unique` variant, which allows us to indicate that a certain term should be treated as the sole term of its equivalence class. We also include a `Malformed` variant, which allows us to indicate that a term should not be included in our search at all.

== Semantics of Polynomials

As a simple example, we revisit the `Polynomials` language. Since the programs expressible here are the functions mapping to polynomials with coefficients in $NN^+$, we can convert to the following form:

$
lambda x_1 dot dot dot x_n . (a_0 + a_1 (v_11 v_12 dot dot dot) + a_2 (v_21 v_22 dot dot dot) + dot dot dot)
$

This leads to the `PolySem` data structure:

```rust
// Semantics of a term (a term taking zero or more arguments and 
// returning a polynomial)
pub struct PolySem {  
  arguments: Vec<Identifier>,
  polynomial: Sum
};

// A sum of products (i.e., a polynomial), with a constant shift
pub struct Sum(i32, Vec<Product>);

// A product of terms, with a constant scaling factor
pub struct Product(i32, Vec<Identifier>);
```

We can translate any expression into this form by expanding polynomials, though we must be careful regarding variable collisions (especially with primitives). In order to ensure that this representation is unique, we can sort our variables & monomials lexicographically. As you might expect, this greatly shrinks the space of programs we are considering.

#linebreak()

#align(center, box(
  width: 60%,
  table(
    columns: (2fr, 3fr, 3fr),
    [Term Size (`N => N`)],[Number of terms (no analysis)],[Number of terms (analysis)],
    [2],[3],[3],
    [6],[18],[4],
    [10],[29],[8],
    [50],[677],[249] 
  ))
)

#v(2em)

Polynomials are simple enough to be analyzed easily and exactly (i.e., we have semantic equality between two polynomial terms iff their analysis yields $alpha$-equivalent `PolySem`s). We cannot hope to do this generally, but even in more complex languages, we can still greatly reduce our search space by informing the enumerator of simple equivalences.

#pagebreak()
