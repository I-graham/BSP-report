= Introduction

Program synthesis is the problem of generating a program from a certain specification, often expressed as a logical constraint. The problem we consider is one of Programming-by-Example synthesis, where instead of a formal specification, we attempt to generate a program using input-output pairs. This is useful in situations where we are interested in discovering exact, possibly complex patterns in a piece of data. This method has strong limitations, as you might expect, but has the advantages that it can work even when datasets are far too small to use statistical methods, that we make very few assumptions about the data (beyond the fact that it has some computable pattern), and that once we generate a program, we can examine and completely understand its behaviour. Some notable applications of this kind of PBE synthesis include: 

#linebreak()

+ "Flash Fill" @gulwani2017program: This is the technology behind Microsoft Excel's autocomplete feature. It is what allows the software to detect and extend a user's actions using very few examples (often even just one).
+ "IntelliCode" @IntelliCode: This is a feature of Visual Studio Code which monitors a user's actions and attempts to discover the patterns of user's edits, and then suggests further refactors (usually only requiring 2 examples).
+ Query Synthesis @Shen2014DiscoveringQB: PBE has been used to develop tools which construct SQL queries based on small numbers of tuple examples of rows which should be fetched.#footnote[This is not the same as Query-by-Example, or QBE, which is a feature of many databases which provides a more user-friendly querying interface, and which has existed since the 1970s.]

#linebreak()

PBE problems are, by their nature, underspecified, as there will usually be many (even infinitely many) programs satisfying any set of input-output constraints, but it does allow us to generate reasonable conjectures about the underying structure of any given piece of data. It has the very powerful property that we do not have to write any kind of formal specification for our program, which is often not much easier than writing the program itself.

== Goals & Motivation

Although the tools developed throughout this project are very general and could be applied to many different areas, we focus especially on synthesizing programs generating integer sequences. One motivating application of this could be in mathematical research, where we might wish to guess patterns in structured integer sequences. This is exactly the concern that the Online Encyclopedia of Integer Sequences (OEIS) was invented to address, and we will use its database to evaluate our program. However, we also discuss how these tools could be applied elsewhere.

We also focus on synthesizing small solution programs. Firstly, because this allows us to avoid overfitting (for example, programs which simply match their inputs to the given input-output pairs, without giving any insight into the larger pattern). Secondly, because it will be helpful in eliminating redundant programs (i.e., programs which are syntactically distinct but semantically identical), vastly reducing our search space. And thirdly, because the minimum description length of a mathematical object or piece of data (i.e., the length of the shortest program generating it) is known as its Kolmogorov Complexity, and though it is incomputable, it is of theoretical interest #footnote[Notably, there are theoretical results showing that if we could compute Kolmogorov complexity, we could approximate Algorithmic Probability, which in turn allows us to compute the source of an infinite sequence correctly and with relatively low error. This formalizes our intuition that, when looking at a piece of data from an unknown source, a "simple" program is more likely to have generated it than a "complex" one. See @Solomonoff for more information.].

Of course, we cannot hope to produce a perfect synthesizer, so a great deal of effort has gone into expanding the space of programs we can search. This equates to (1) trying to shrink the search space as much as possible, and (2) expanding the portion of the search space we can feasibly examine as much as possible. This means both pruning our search wherever possible and emphasizing performance in our code, both of which come with the cost of some added complexity in our synthesizer.

== Report Structure

Each of the main chapters of this report covers a different aspect of this program synthesizer, in varying levels of detail. We discuss the reasons behind each major design decision, as well as their strengths and limits compared to other possible decisions.

The main chapters cover:
+ The interpreter used to evaluate programs.
+ The enumerator which allows us to iterate over certain program spaces.   
+ The incorporation of semantic analysis into our search.
+ The use of the Metropolis-Hastings algorithm to expand the scope of our search space. 
+ The results and effectiveness of the synthesizer.

== Choice of Technology

Because of the need for efficiency, I chose to use Rust to implement this synthesizer. This did complicate its implementation, it allowed me to make optimizations which would not have been possible in a higher level language (such as Haskell, which is probably the language which would have made a simple version of this implementation the simplest).

In order to be clear and precise, I try wheverever possible to show the relevant code, but for the sake of brevity and readability, I omit parts of the code which add complexity without offering any insight (type cases, clones, trait derivations, unreachable code branches, etc...), meaning code snippets as they appear in this document may not be strictly correct #footnote[If you are unfamiliar with Rust, the code as shown should be readily comprehensible. If you are familiar with Rust, please ignore any ownership or borrow checker violations.]. Wherever library types are used, I explain their purpose, without delving into their meaning or implementation. However, if you would like more information, see #link("https://doc.rust-lang.org/std")[the documentation].

#pagebreak()
