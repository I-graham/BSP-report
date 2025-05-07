#set heading(numbering: "1.1")
#set page(paper: "a4", margin: 1.1in, numbering: "1")
#set par(leading: 0.80em, spacing: 0.90em, first-line-indent: 1.8em, justify: true)
#set text(font: "New Computer Modern", spacing: 100%, size: 12pt)
#show math.equation: box 
#show raw.where(block:true): it => {
  set block(inset: 5%, above: 1em, below: 2em)
  set text(size: 09pt)

  it
}
#show heading: set block(above: 1.4em, below: 1em)
#show enum: set block(above: 2em, below: 2em)
#set list(marker: [$triangle.filled.small.r$])

#include "title.typ"
#include "abstract.typ"
#include "toc.typ"

#include "introduction.typ"
#include "interpreter.typ"
#include "enumeration.typ"
#include "semantics.typ"
#include "encoding.typ"
#include "metropolis.typ"
#include "conclusion.typ"

#include "appendix.typ"

#bibliography("refs.bib")
