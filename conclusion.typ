= Results

The two languages we consider in this section are `Polynomials`, and `NumLogic`, a slight modification/extension of the conjunctive query language shown in @Grammar, with the primitives below (along with a brief description):

#v(-2em)

```haskell
-- Basic primitives:
mul :: Atom => Atom => Atom
mul a b = a * b 

pow :: Atom => Atom => Num
pow b k = b^k

prime :: Var => Pred
prime = {true if n is prime}

and :: Pred => Conj => Conj
and p c = p && c

eq :: Atom => Atom => Pred
eq a b = a == b

less :: Atom => Atom => Pred
less a b = a < b

divisor :: Atom => Atom => Pred
divisor p q = p > 1 && q % p == 0

-- Reductions over ranges:
-- Check if a predicate is satisfied
exist :: Var => (Var => Bool) => Bool
exist v p = ∃n∈[1,..,v] (p n)

-- Count values with a property
count :: Var => (Var => Bool) => Num
count v p = #n∈[1,..,v] (p n)

-- Sum up values
sigma :: Var => (Var => Num ) => Num
sigma v f = Σn∈[1,..,v] (f n)

-- Type casts:
atom :: Var  => Atom
num  :: Atom => Num 
conj :: Pred => Conj 
bln  :: Conj => Bool
```

For `NumLogic`, we also include some pretty-printing functionality, which we will use instead of displaying the full programs. For example, we write `∃n<=k [Prime(n)]` instead of `exist k (n -> bln (conj (prime(n))))`.

== Enumerative Search

The enumeration is significantly more powerful than might be expected, especially using caching and semantic analysis. For example, see the times needed to enumerate `NumLogic` programs of type `Var => Bool` of different sizes in @times. This technique was able to discover formulas for many entries in the OEIS, sometimes in interesting ways (see A008585, for example). All of the sequences below can be generated in less than ~20 seconds (They have size < 40):

+ A000961: Prime powers (`f -> ∃k<=f [∃m<=f [Prime(m) && (f)=(m^k)]]`)
+ A002808: Composite numbers (`f -> ∃k<=f [(k)|(f) && (k)<(f)]`)
+ A000430: Primes and squares of primes (`f -> ∃k<=f [Prime(k) && (f)|(k*k)]`)

If we instead synthesize terms of the type `Var => Num`:

+ A230980: The number of primes below $n$ (`f -> #k<=f [Prime(k)]`)
+ A168014: The sum of $i$ up to $n$ of the number of divisors of $i$ (`f -> Σk<=f [#m<=f [(m)|(f)]]`)
+ A000290: The squares (`f -> Σk<=f [(f)]`)
+ A000590: Sums of 5th powers (`f -> Σk<=f [Σm<=k [(k*k*k*k)]]`)
+ A325459: Sums of nontrivial divisors (`f -> Σk<=f [#m<=k [(m)|(k) && (m)<(k)]]`) 
+ A010051: The characteristic function of the primes (`f -> #k<=f [Prime(f^k)]`)
+ A128913: $n pi(n)$ (`f -> Σk<=f [#m<=f [Prime(m)]]`)
+ A008585: Multiples of 3 (`f -> Σk<=f [#m<=k [(f^m)|(f*f*f))]`)

== Metropolis-Hastings Search

In cases where the solution program is small, enumeration is always faster than stochastic search. For simple languages, the Metropolis-Hastings synthesizer allows us to search for larger programs than would be possible with enumeration alone, though quite unreliably. For example, in `Polynomials`, consider the sequence $a_n = 6 n^4 + 6 n^2$. The shortest program generating this has size 30, and (on my machine) takes 19 seconds to generate through enumerative synthesis. A stochastic search (starting with the smallest program of type `N => N`, so as to avoid a biased starting point) on the other hand, is usually able to find it very quickly (usually around 1-2s, but sometimes as fast as 0.3s). However, when it does not find a solution quickly, it often does not find one at all.

In more complex settings, such as in the `NumLogic` language, I was not able to make stochastic search effective. In both cases, the ineffectiveness is likely due to the synthesizer's tendency to search for increasingly large terms, but also is probably because of poorly tuned parameters and a scoring function which is not particularly useful when the proposal drifts too far from the solution. There are a lot of potential improvements to be made, and this would be interesting to explore further.

== Reflections

This project was a fascinating learning opportunity. It was especially interesting to be able to apply several concepts from my recent modules in unexpected ways, most notably Lambda Calculus & Types and Principles of Programming Languages. While the final codebase sits at only around 5,000 lines, large portions had to be repeatedly rewritten from scratch to acheive the final result. This was the most difficult project I've undertaken, and even steps that seemed simple at the start (such as implementing the enumerator efficiently) ended up being months of careful effort. There are still many directions this work could continue in, for example, using information about the provided input-output examples in the enumeration process, or experimenting with different approaches to the stochastic search. 

#pagebreak()
