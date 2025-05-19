= Introduction

Program synthesis is the problem of generating a program from a certain specification, often expressed as a logical constraint. The problem we consider is one of Programming-by-Example (PBE) synthesis, where instead of a formal specification, we attempt to generate a program using input-output pairs. This is useful in situations where we are interested in discovering exact, possibly complex patterns in a piece of data. This method has strong limitations, as you might expect, but has the advantages that it can work even when datasets are far too small to use statistical methods, that we make very few assumptions about the data (beyond the fact that it has some computable pattern), and that once we generate a program, we can examine and completely understand its behaviour. Some notable applications of this kind of PBE synthesis include: 

+ "Flash Fill" @gulwani2017program: This is the technology behind Microsoft Excel's autocomplete feature. It is what allows the software to detect and extend a user's actions using very few examples (often even just one).
+ "IntelliCode" @IntelliCode: This is a feature of Visual Studio Code which monitors a user's actions and attempts to discover the patterns of user's edits, and then suggests further refactors (usually only requiring 2 examples).
+ Query Synthesis @Shen2014DiscoveringQB: PBE has been used to develop tools which construct SQL queries based on small numbers of tuple examples of rows which should be fetched.#footnote[This is not the same as Query-by-Example, or QBE, which is a feature of many databases which provides a more user-friendly querying interface, and which has existed since the 1970s.]

PBE problems are, by their nature, underspecified, as there will usually be many (even infinitely many) programs satisfying any set of input-output constraints, but it does allow us to generate reasonable conjectures about the underlying structure of any given piece of data. It has the very powerful property that we do not have to write any kind of formal specification for our program, which is often not much easier than writing the program itself. 

== Goals & Motivation

Although the tools developed throughout this project are very general and could be applied to many different areas, we focus especially on synthesizing programs generating integer sequences. One motivating application of this could be in mathematical research, where we might wish to guess patterns in structured integer sequences. This is exactly the concern that the Online Encyclopedia of Integer Sequences (OEIS) was invented to address, and we will use its database to evaluate our program. However, we also discuss how these tools could be applied elsewhere.

We also focus on synthesizing small solution programs. Firstly, because this allows us to avoid overfitting. Secondly, because it will be helpful in eliminating redundant programs,  vastly reducing our search space. And thirdly, because the minimum description length of a mathematical object or piece of data (i.e., the length of the shortest program generating it) is known as its Kolmogorov Complexity, and though it is incomputable, it is of theoretical interest. #footnote[Notably, there are theoretical results showing that if we could compute Kolmogorov complexity, we could approximate Algorithmic Probability, which in turn allows us to compute the source of an infinite sequence correctly and with few errors. This formalizes our intuition that, when looking at a piece of data from an unknown source, a "simple" program is more likely to have generated it than a "complex" one. See @Solomonoff for more information.]

Of course, we cannot hope to produce a perfect synthesizer, so a great deal of effort has gone into expanding the space of interesting programs that we can search. This equates to narrowing the search as much as possible and expanding the portion of the search space we can feasibly examine as much as possible. This means we should both prune our search wherever possible and emphasize performance in our code, both of which require added complexity in our synthesizer.

== Report Structure

Each of the main chapters of this report covers a different aspect of this program synthesizer, in varying levels of detail. We discuss the reasons behind each major design decision, as well as their strengths and limits compared to other possible decisions. The main chapters cover:
+ The interpreter used to evaluate programs.
+ The program enumeration algorithm.
+ The incorporation of semantic analysis into our search.
+ Different kinds of encoding schemes.
+ The use of the Metropolis-Hastings algorithm to expand the scope of our search space. 
+ The effectiveness of the synthesizer.

== Choice of Technology

Because of the need for efficiency, I chose to use Rust to implement this synthesizer. This complicated the implementation, but allowed me to make optimizations which would not have been possible in a higher level language (such as Haskell, which probably would have made building a prototype simpler).

In order to be clear and precise, I try wheverever possible to show the relevant code, but for the sake of brevity and readability, I omit parts of the code which add complexity without offering any insight (type casts, clones, trait derivations, unreachable code branches, etc...), meaning code snippets as they appear in this document may not be strictly correct. #footnote[In particular, it may include Rust-specific errors, such as ownership/borrow checker violations.] 

#pagebreak()
