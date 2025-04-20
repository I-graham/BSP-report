#set heading(numbering: "1.1")
#set page(paper: "a4", margin: 1.1in)
#set par(leading: 0.80em, spacing: 0.90em, first-line-indent: 1.8em, justify: true)
#set text(font: "New Computer Modern", spacing: 100%, size: 12pt)
#show raw: set block(above: 2em, below: 2em)
#show heading: set block(above: 1.4em, below: 1em)
#show link: underline

#include "title.typ"
#include "abstract.typ"
#include "toc.typ"

#include "intro.typ"
#include "interpreter.typ"

#bibliography("refs.bib")
