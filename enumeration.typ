#import "@preview/curryst:0.5.1": rule, prooftree

#let par_eq(eq) = block(100%, eq)

= Program Enumeration

#let normal_terms = [$beta$-normal terms]

The core of our synthesizer is its enumeration algorithm, which takes as input a language, a size and a type, and enumerates the #normal_terms of that size with that type in that language. The restriction to #normal_terms is useful because: 

+ Every normalizable $lambda$-term has a unique normal form, so we never generate two $beta$-equivalent terms. #footnote[However, we may still generate terms which are equivalent in a particular language (for example $(lambda x y . (+) x y)$ is equivalent to $(lambda x y . (+) y x )$) if $(+)$ has its usual definition. We might also generate several $eta$-equivalent terms. Both of these concerns can be addressed using the semantic analysis tools discussed in the next chapter.]
+ Every typable $lambda$-term is normalizable, so we don't reduce the expressibility of our language by only considering #normal_terms.
+ It vastly reduces our search space.

The term enumerator is the most performance-critical part of the code, and so has been rewritten several times with increasing complexity to reach its current level of performance. Because of this, we include very little code in this section, and focus on the high level approach.

== Basic Algorithm

Our enumeration method is based on the observation that every $lambda$-term in $beta$-normal form has the following structure: #block(width:100%, $ lambda x_1 dot dot dot x_n . v t_1 dots t_m $) where $v$ is a variable and ${t_i}$ are also in $beta$-normal form. 

#linebreak()
This suggests a recursive algorithm, where, given some type $T$, we:

+ Enumerate over the variables $v$ which can appear as the head of a term of type $T$ (i.e, variables with types of the form $A_1 => dot dot dot => A_k => T$, where $k >= 0$). We then enumerate all #normal_terms of types ${A_i}$, and apply $v$ to each combination of them.
+ If $T eq.triple A => B$, then we also enumerate the terms $lambda x . M_i$ of type $B$, where ${M_i}$ are #normal_terms which may include some fresh variable $x$ of type $A$.

This corresponds to the following set of rules, which types exactly the #normal_terms in any context $Gamma$.

#{
  show: rest => align(center, rest)

  let rules = (
    rule(
      name: [(Abs)],
      [$Gamma tack.r (lambda x . b) : A => B$],
      [${Gamma; x : A} tack.r b: B $]
    ),
    rule(
      name: [(App) <App>],
      [$Gamma tack.r v a_1 dot dot dot a_n : T$],
      [$n >= 0$],
      [$v: (A_1 => dot dot dot => A_n => T) in Gamma$],
      [$Gamma tack.r a_i : T_i$]
    ),
  )

  for rule in rules {
    linebreak()
    prooftree(rule)
  }
}
#linebreak()
Since we only want to generate terms of a fixed size, at every point in the enumeration, we must make sure to keep track of how large the term is so far, so that we can backtrack whenever it gets too large.

== Caching

While the above technique could be implemented quite simply, it is not easy to attain high performance. The most important optimizations we can make are those which prune the search space as early as possible. Even costly optimizations of this sort will usually save a lot of time. There are many possible techniques of this sort which could be used, but we discuss only the two most simplest and most important optimizations:

=== Query Pruning

A search (or enumeration) query in a particular language is defined by the type and size of the enumerated terms. We can maintain a cache with the results of previously made queries.

```rust
// A search query
type Query = (Type, usize);

// A map from queries to results
type PathCache<L: Language> = HashMap<Query, SearchResult<L>>;

// Since some queries have large results, we place a limit on how many terms we can
// can store in a single cache entry.
pub const CACHE_SIZE_LIMIT: usize = 16;

// The result of a query
pub enum SearchResult<L: Language> {
    Unknown, // If the search is still in process
    Inhabited {
        // The first few Terms output by this query  
        cache: Vec<Term>,
        // The number of terms that have been found
        // (may be more than those that have been cached) 
        count: usize,
        // The state of the search after the cached terms have been enumerated.
        state: Option<Box<SearchNode<L>>>,
    },
    Empty, // If the search does not yield any terms 
}
```

Whenever we begin a new search, we consult the cache to see if this query has been made before. If so, we either skip the search (if it's `Empty`), or use the cached values (before picking up the search at the point where the previous search ran out of space in the cache). This is extremely useful, since many queries yield empty results, or otherwise have few results, even if the search would otherwise be very large.

=== Argument Pruning

#let app_link = link(<App>)[Application]

When we use the #app_link rule, we have to consider every combination of argument sizes. For example, if we are trying to generate a term of type `N` and size $k$ by applying arguments to the function `(+) : N => N => N`, then we will reach a point in the search where we have the following search tree:

#let app = $circle.stroked.small$
#import "@preview/cetz:0.3.4": canvas, draw, tree
#align(center)[
  #canvas({
    import draw: *
    
    set-style(content: (padding: .1))

    tree.tree(([#app], ([#app], [`(+)`], [`Arg1`]), [`Arg2`]), spread: 1.3)

  })
]

Here, `Arg1` and `Arg2` may have any of the $k-4$ combinations of sizes adding up to $k-3$. If we instead used a function taking $n$ arguments, there would be $O(k^(n-1))$ possible size partitions. We would benefit from pruning this search space, so that we don't begin to enumerate all the possible values of one argument before realizing we have chosen an empty size partition.

It is a bit difficult to express this algorithm in (pseudo-)code without going into excessive detail about the implementation of the enumeration algorithm, but we can again take advantage of our previous cache, and prune any search paths which correspond only to partitions which do not yield any output terms. This allows us to search only partitions where the result of the search for each argument is either `Unknown` or `Inhabited`.

=== Caching Considerations

There are a few more considerations we have to take into account to get our implementation correct. For example:

+ When we abstract over a variable, we may invalidate previous cache entries. For example, a certain language may not have any variables of type $T$, so if we run the query $(T, 1)$, we will mark it empty in the cache, but if we later make the query $(T => T, 2)$, then can find the term $lambda x . x$, which has a subterm (that is, $x$) of type $T$ and size 1, which contradicts our cache entry.
+ When we begin a search for the first time, we mark it as `Unknown` in the cache. Later, when we complete it, we mark it `Inhabited` or `Empty`. We may select a partition for the #app_link which includes a search with an `Unknown` result for a certain paramter, which might turn out to be `Empty`. When this happens, we have to be careful to close ongoing searches properly, which requires care. Similarly, we must be careful when entering a search using a state from an `Inhabited` search result.

#pagebreak()
