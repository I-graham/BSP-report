#counter(heading).update(0)
#set heading(numbering:"A.1")

= Appendix

== Lambda Calculus Basics <lambda_glossary>

#let term = box[$lambda$-term]
#let terms = box[#(term)s]

+ a *#term* is either:
  - a variable,
  - an abstraction over another #term (i.e., $lambda x . m$ where $m$ is a #term),
  - an application of two #terms (i.e., $(m n)$ where $m$, $n$ are #terms).

+ The *subterms* of a #term are all the #terms which appear within it (including itself).

#let redex = box[$(lambda x . M) N$]

+ A *redex* (from reducible expression) of a #term is a subterm of a #term of the form #redex.

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

== Enumeration Time Table <times>

#align(center, box(
  width: 70%,
  table(
    columns: (1fr, 2fr, 2fr),
    align: center,
    [Size],[\# of terms],[Enumeration time (s)],
    [8],[1],[0.00020],
    [20],[8],[0.00295],
    [25],[52],[0.01268],
    [26],[291],[0.03499],
    [27],[220],[0.03098],
    [28],[454],[0.07579],
    [29],[344],[0.08978],
    [30],[373],[0.18885],
    [31],[390],[0.22263],
    [32],[2231],[0.51554],
    [33],[1080],[0.57150],
    [34],[5138],[1.3557],
    [35],[2558],[1.4925],
    [36],[5929],[3.1751],
    [37],[3788],[4.2012],
    [38],[15703],[8.3403],
    [39],[6516],[15.090],
    [40],[56226],[24.417],
    [41],[15572],[40.995],
    [42],[106827],[77.327],
    [43],[29220],[102.68],
    [44],[171195],[183.61],
    [45],[45822],[256.10],
    [46],[496258],[483.86],
    [47],[89844],[746.35],
    [48],[1310846],[1282.98],
    [49],[184442],[2363.75],
    [50],[2313868],[3836.52]
  )
)) 

#pagebreak()
