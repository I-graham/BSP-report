#set page(margin: 1.8in)

#align(center)[
  #set par(justify: false)
  #set heading(numbering: none)
  = Abstract
]

#linebreak()

#set par(justify: true, first-line-indent: 0pt)

Program Synthesizers are programs that write programs, usually with a formal logical specification. In this project, we focus on designing and building a PBE (Programming-by-Example) Synthesizer, with the primary goal of being able to deduce from a piece of data (such as, a set or sequence of integers), a program that might have generated it, or which can explain most of its content. Synthesizers of this sort are useful for pattern recognition in settings where datasets are small and approximate answers are not desired. We use a combination of enumerative and Monte Carlo techniques, and discuss the practical and theoretical implications of different possible design choices. The resulting tool is very general, and can be used to evaluate and compare the expressivity of programming languages, or to try to determine the Minimum Description Length of different sequences in (total) programming languages. We discuss the results of some such experiments, and discuss potential future extensions.

