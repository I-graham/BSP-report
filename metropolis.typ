= Stochastic Search

While enumeration can be used to search for small programs, it relies on completely exhausting the search space, which is usually infeasible. To attempt to mitigate this, we show how to use a stochastic method to generate larger terms. 

== Metropolis-Hastings

The Metropolis-Hastings algorithm is an algorithm to sample from a complex probability distribution. In our case, we will define a distribution that assigns the highest likelihoods to programs that perform best, and then sample from it in the hopes that, since correct are the programs with the highest probability, we will pick a program which performs well.

This is a Markov Chain Monte Carlo method, meaning it works by beginning with some initial candidate and repeatedly transitioning to new ones. In order to implement the Metropolis-Hastings algorithm, we will need to define:

+ A space $X$ over which our distribution acts.
+ A distribution $PP : X => RR$.
+ A proposal distribution $g(x|y)$, which we can efficiently sample from. This gives the probability of proposing $x$ given that the previous proposal was $y$. It should be possible to compute $g(x|y)/g(y|x)$ efficiently, and we must ensure that $g(x|y)$ is nonzero iff $g(y|x)$ is.

Once we have these, the algorithm consists of:
  + Choosing an initial candidate $x_1$.
  + Selecting a proposal $p_n$ according to $g$.
  + Set $x_(n+1) = p_n$ with probability $min(1,(PP(x_n)g(p_n|x_n))/(PP(p_n)g(x_n|p_n)))$, and $x_(n+1) = x_n$ otherwise. 
  + Repeating the previous 2 steps many times, then selecting the candidate with the highest score.

== Application to a Functional Setting

The method described here was inspired by @StochSuper, in which the Metropolis-Hastings algorithm is used to generate "Superoptimized" assembly code (meaning, code which is not just efficient, but the most efficient version way of accomplishing its purpose). Converting to a functional setting brings a few challenges. For example, it's unclear:

+ How to evaluate the correctness of a program. In the assembly setting, programs were evaluated based on the Hamming distance between CPU registers after executing the original and synthesized programs. However, this is probably not effective in a functional setting.

+ How to mutate programs. In the assembly setting, there were several different kinds of modifications that were possible which do not translate to a functional setting (such as swapping the order of two instructions or replacing one with a NOOP).
#linebreak()

For the first issue, make a simple choice: The correctness of a program is just how many examples it evaluates correctly. Then, we can define $PP(x) = e^(C * N(x))$, where $C$ is a parameter which we can tune, and $N(x)$ is the number of correct answers.

For the second issue, we introduce two new properties to `Language`s:
  + `SMALL_SIZE: usize`: The largest size we can efficiently enumerate entirely.
  + `LARGE_SIZE: usize`: A larger size, which will be more (but not prohibitively) expensive to compute.
Now, we can define three types of mutations:
  + Variable Swaps, in which we replace one variable in a term with another of the same type.
  + Small Subterm Swaps, in which we replace a small subterm with another of the same size (and type).
  + Large Subterm Swaps, in which we replace a large subterm with another of the same type, (though possibly not of the same size). This is important because it allows our candidate program to change size.

We must be careful to ensure that the terms we generate are always in $beta$-normal form. If we do not, then we violate the requirement that $g(x|y)$ is nonnegative iff $g(y|x)$ is, since our enumerator never produces terms which are not in $beta$-normal form.

We can select replacement terms uniformly at random by enumerating terms (using reservoir sampling to avoid having to store the entire program space in memory). Whenever we make a large swap, in order to compute $g(x|y)/g(y|x)$, we may have to enumerate not only the possible replacements, but also the terms with the size and type of the replaced node, even though we don't use any of them. Again, we can use caching to mitigate this issue.#footnote[We could also try to use a more clever counting algorithm which does not generate terms as it counts them, but this would not work for languages with nontrivial semantics.]

Another issue is that the candidate's size tends to grow without bound. This is because, when we perform a large swap, we are usually replacing a small subterm with a large one (because there are many more small subterms than large ones). We can compensate by biasing our sampling algorithm to try to replace terms with others of roughly the same size, but this is difficult since it may not always be possible to construct terms of the right type of a specific size. To mitigate this issue, we can include a correction term in $PP(x)$ which punishes terms for being too large. Again, for brevity, we omit the implementation.

#pagebreak()
