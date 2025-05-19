= Encoding Schemes

The tools we have developed for narrowing our search space thus far may seem primitive, but with some care, we can exert greater control over the search space.

== Query Selection

The most obvious way to restrict the enumeration is by modifying the type of the program we are enumerating, and the context we feed into it. For example, considering the `Polynomials` language and an integer sequence ${a_n}$, we could choose to synthesize:

- A mapping `f : N => N` from $n arrow.r.bar a_n$.
- A function `p : N => N => N` which should be iterated: $a_(n+1) = p(a_n)$, using the given value of $a_0$ (For example, if $a_n = sum_(k = 0)^n k$).
- Arguments `z` and `f` to the natural fold (or catamorphism) on the (Peano) naturals, defined as:
```haskell
foldNat : N => N => (N => N => N) => N
foldNat Zero     z _ = z 
foldNat (Succ n) z f = f (Succ n) (foldNat n z f)
``` 
- A function `p : (N => N) => N => N` whose fixed point is $n arrow.r.bar a_n$. In this case, our program `p` essentially acts as a recursive definition, akin to how recursive functions are defined in denotational semantics: $a_n = f^infinity (n) "where" f^n (n) = p(f^(n-1), n)$. 
- Many other possibilities.

#linebreak()

Additionally, there are theoretical results about the expressiveness of programs of different types. For example, if we were concerned with sequences of objects of a finite type `A`, we could provide an `equal? : A => A > Bool` primitive and restrict ourselves to the Regular Languages by constructing terms of type `(A => Q => Q) => Q => Q` (where `Q` is a type encoding the states of a DFA recognizing the language). Alternatively, we could restrict ourselves to PTIME, PSPACE, $k$-EXPTIME, or $k$-EXPSPACE (for any $k$).#footnote[See @TLCe or @LetCalc for more.]

== Grammars Through Types <Grammar>

As mentioned previously, our interpreter erases all type information at runtime. What this means is that the type system we provide only serves to indicate to the enumerator where each function is syntactically valid. This means that we can take advtantage of this to specify a precise grammar for our language, beyond the basic restriction of it being a functional language.

For example, we might want to search the space of _conjunctive queries_ from database theory, which form a powerful language with simple semantics: #h(60%)
#linebreak()
#box(width: 100%)[$
  lambda x_1 dot dot dot x_n. exists v_1 dot dot dot v_m and.big_i P_i
$]
where $P_i$ are atomic formulae. These could be defined with the following simple grammar:
#grid(
  columns: (14fr, 1fr, 14fr),
  [$
    Q &-> lambda v Q \
    Q &-> B \
  $],[$
    B &-> exists v B \
    B &-> C \
  $],[$
    C &-> P and C \
    C &-> P \
  $]
)
For any such rules, we can construct primitives with corresponding types, so that program enumeration corresponds to searching the grammar:#footnote[Here, our primitive must capture the `Context` in order to recursively evaluate its argument.]

```rust
// Helper functions to unwrap terms
let int = |t: &Term| t.get::<u32>();
let bln = |t: &Term| t.get::<bool>();

// B -> C
let boolean = builtin! {
  Conjunction => Boolean
  |c| => c.clone()
};

// B -> ∃v.B 
let exists = builtin! {
  // `exists l p` means `There exists an n in {1,...,l} such that p(n)` 
  (Variable => Boolean) => Variable => Boolean
  context |input, pred| => Term::val(
    (1..=input) // Search range {1,...,n}
      .any(|n|  // Evaluate predicate at each n
        bln(&context.evaluate(&term!([program] [:n])))
      )
  )
};

// C -> P
let conjunction = builtin! {
  Predicate => Conjunction
  |p| => p.clone() 
}

// C -> P && C
let and = builtin! {
  Predicate => Conjunction => Conjunction
  |p, b| => Term::val(
    bln(&p) && bln(&p)
  )
};
```

Notice that there is a direct correspondance between the grammar and the terms of our language: every type corresponds to a non-terminal, and every function corresponds to a production rule, with parameters corresponding to the non-terminals in the production rule, and the return type corresponding to the produced non-terminal.#footnote[Note that the only non-obvious correspondance is between $b$ and `Variable => Boolean`. this type is chosen because we want $b$ to be parametrized by a new variable. this breaks the correspondance because the grammar does not capture this behavior. instead, it is usually implied in our variable terminals. $Q$ does not have a corresponding function because $lambda$-abstraction is a basic feature of functional languages.]

== Semantic Pruning

Semantics can be useful for narrowing our search space beyond just detecting duplicate terms. For example, say we wanted to modify our `Polynomials` language to include a construct to define variables, similar to Haskell's `let` expressions, so that we could, for example, write something akin to `let y = x + 1 in y*y*y` instead of having to write `x*x*x+(1+1+1)*x*x+(1+1+1)*x+1`. This could be very useful to our synthesizer, since it allows complex (but interesting) programs to have smaller representations. Unfortunately, our simple functional languages based on the $lambda$-calculus cannot support this construct. We might try to get around this restriction by converting let constructs to $beta$-redexes:

#align(center, block[
  (`let v = d in e`) $arrow.r.long.bar$ `(λv.e)d`
])

Since our enumerator only generates terms in $beta$-normal form, programs of this form will never be generated. We can get around this by intruducing a new primitive:

```rust
let abstract = builtin! {
  (N => N) => N => N
  |e, d| => term!([e] [d])
};
```

This is because while `(λv.e)d` is not in $beta$-normal form, `(abstract e d)` is (as long as `e` and `d` are $beta$-normal). However, if we do this, we will generate well-typed terms such as `abstract (plus one) zero` instead of `plus one zero`, which many be undesirable. If we have semantic analysis, the enumerator will detect these duplicates once they are generated, but in more complex situations, we could avoid this by marking any term of the form `abstract e` as `Malformed` if `e` is not a $lambda$-abstraction which uses its argument.

#pagebreak()
