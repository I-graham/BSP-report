#counter(heading).update(0)
#set heading(numbering:"A.1")

= Appendix

== Lambda Calculus Basics <lambda_glossary>

#let term = box[$lambda$-term]
#let terms = box[#(term)s]

+ A *#term* is either:
  - a variable,
  - an abstraction over another #term (i.e., $lambda x . M$ where $M$ is a #term),
  - an application of two #terms (i.e., $(M N)$ where $M$, $N$ are #terms).

+ The *subterms* of a #term are all the #terms which appear within it (including itself).

#let redex = box[$(lambda x . M) N$]

+ A *redex* (from reducible expression) of a #term is a subterm of a #term of the form #redex.

+ An occurence of a variable $v$ in a #term $t$ is *bound* if it appears in a subterm $t = lambda v . u$. Otherwise, it is *free*. We say a variable is *fresh* if it does not appear in any of the #terms under discussion.

+ Terms are *$alpha$-equivalent* if they are equal up to the renaming of bound variables.

+ *$beta$-reduction* is the operation mapping a redex #redex to $M[N\/x]$ (that is, which substitutes $N$ for $x$ in the usual way, accounting for variable collisions). When we say a #term *$beta$-reduces* to another, this may require more than several reduction steps.

+ Two #terms are *$beta$-equivalent* if they $beta$-reduce to a common term (up to $alpha$-equivalence).

+ *$eta$-reduction* is the operation mapping a term $(lambda x . M x)$ to $M$. $eta$-equivalent terms are not necessarily $beta$-equivalent. 

#let bnf = box[$beta$-normal form]

+ A #term is in *#bnf* if it does not contain any redexes. When it exists, the #bnf is unique and the same for all $beta$-equivalent #terms.

+ All #terms have the form $lambda x_1 dot dot dot x_k . t_1 dot dot dot t_m$ where ${x_i}$ are variables, ${t_i}$ are #terms, $k >= 0$, and $m >= 1$. We say $t_1$ is the *head* of the #term.

+ When the head of a #term is a variable, it is in *head normal form*.

+ The *order* of a #term is the order of its type, defined as:
$
"order"(T) := cases(
  0 &"if" T "is a variable",
  "max"(1+"order"(A), "order"(B)) quad &"if" T eq.triple A => B 
) 
$

#pagebreak()
