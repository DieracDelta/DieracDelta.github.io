---
author:
  name: "Justin Restivo"
date: 2020-02-02
linktitle: Writing a Thesis
title: Writing a Thesis
type:
- post
- posts
weight: 10
series:
- Justin's Life
aliases:
- /blog/writing\_a\_thesis
---

I intend this blog entry to summarize how I went about writing my masters thesis using latex. My goal is to showcase things that did and did not help me in this endeavor.

# Organization #

One of the first things I did when writing this was really consider organization. One of the things that bit me the most previously was organization. I wanted brief, informal descriptions of what I was planning to do with each section, subsection, subsubsection, and paragraph. Morally speaking, the right way to do this would be to add in a custom description environment that adds in a description that is ignored when you compile. However, at the time I thought macros might make more sense, so I added in multiline macros that would take in a description, todos, and the actual paragraph/subsection/section content. This didn't work well for several reasons:

- Latex doesn't name parameters so on more than one occasion, I would put the wrong order of arguments, which would result in latex not compiling paragraphs into my thesis.
- Compiler errors if I forgot to include a {}.
- No native editor folding for the macros, which often made the thesis hard to read at a high level, since I would have all this extra information that I didn't want to see.
- The library was disgusting and made me hate latex. Latex's syntax for things like counters and if statements is really disgusting.

While this may sound really negative, I will say that having some text describing the intent of each paragraph was incredibly helpful despite these pitfalls. Organizationally, I did not struggle because of these friendly reminders. Next time, though, I'll probably rewrite my library to use environments instead of macros.

Another issue I ran into was that the file I was editing ended up getting really really long. I remedied this by splitting out into a *lot* of files. My tree looked like the following:

```
├── code_snippets
├── figures
├── justins_thesis_tools.sty
├── lgrind.sty
├── main.tex
├── Makefile
├── ref.bib
├── sections
│   ├── abstract.tex
│   ├── appendix_a.tex
│   ├── background.tex
│   ├── conclusion.tex
│   ├── cover.tex
│   ├── design
│   ├── design.tex
│   ├── discussion.tex
│   ├── evaluation.tex
│   ├── implementation.tex
│   ├── introduction.tex
│   └── related_works.tex
├── stats
│   ├── BENCHMARKS
│   │   ├── graphs.py
│   │   ├── RAW_DATA
└── tables
```

So, I was able to group by code snippets, figures, tables, and section. This made navigation way easier as I could just recursively include files, and my edits were far more modular as they only changed a single file with a clear purpose in mind. I had a bunch of pngs in the stats directory (which I'll talk about later) that would be generated when I ran my graph.py python script that parsed the data in RAW_DATA.

# Compilation #

Compiling a latex project this large is bound to be a pain. I ended up constructing a Makefile to do it for me. It took 3-4 consecutive compilation attempts to get everything (including bibliography, figures, and at one point a glossary) inside the pdf. I oscillated between xelatex and pdflatex, but ended up using pdflatex because xelatex would not compile with the includegraphics macro, which I needed. To automate the process, I used latexmk, which will continually compile until a non-error result is found. I wrapped this inside a makefile that would both build the document and clean up the excess files used when building. The command I built was quite long. Something along the lines of:

```
latexmk -pdf -bibtex -pdflatex="pdflatex  %O  --shell-escape %S" -verbose -file-line-error -synctex=1 -interaction=nonstopmode
```

The flags are somewhat self explanatory. The pdf flag says to make pdf output. The bibtex flag is necessary to produce a bibliography. The shell escape flag is needed to deal with the includegraphics issues I was encountering. The verbose flag makes for a longer log. The synctex flag is there to play nicely with my vim-like pdf reader (zathura). The interaction flag allows for compilation to not rely upon user input.

In addition to this I had contiuous compilation set up with vim. I'll talk about this more later on but essentially you can set up vimtex to use exactly those flags by setting the relevant variable in your init.vim:
```
let g:vimtex_compiler_latexmk = {
    \ 'options' : [
    \   '-pdf',
    \   '-bibtex',
    \   '-pdflatex="pdflatex %O --shell-escape %S"',
    \   '-verbose',
    \   '-file-line-error',
    \   '-synctex=1',
    \   '-interaction=nonstopmode',
    \ ]
    \}
```


# Visuals #

Throughout my thesis, I frequently needed to illustrate my work with helpful visuals. Specifically, I needed to include code snippets, pictures, plots, and tables. I figured out how to mostly just use latex for these specifics, which I will subsequently detail.

## Code Snippets ##

I needed to include code snippets. I used minted for this. Minted is a latex library intended exactly for this purpose. I used it and everything turned out quite nicely. I even make ultisnip snippets for it:


```
snippet rust
\begin{figure}[ht]
  \begin{minted}[autogobble]{rust}
  $1
  \end{minted}
  \caption{$2}
  \label{fig:$3}
\end{figure}
endsnippet
```

## Figures ##

I needed to write figures. I'm not particularly artistically gifted but I needed professional pictures. So, I used tikz. Tikz allows you to write a text representation of your picture. You can label nodes and then draw lines (and optionally arrows) between the lines. You can also make fancy shapes with textures. Maybe I'll talk about this specifically later on in another blog post.

## Plots ##

I needed to plot a bunch of figures dynamically based on raw text files. This proved very difficult to do in latex. As a result, I just used the normal matplotlib and python to parse raw text files and plot the results into a png. Note that these pngs lacked bounding boxes, so when I "includegraphics"-ed them, I had to manually specify the bounding box as a parameter. This was somewhat of a pain and felt very tedious.

## Latex Tables ##

I needed to include multidimensional tables. The way I went about this was with the multirow package. This allowed me to take up multiple columns with the multirow macros and multiple columns with the multicolumn macro. The multirow allows one entry to take up the space of multiple rows, and similarly for the multicolumn macro.

# Bibliography #

The bibliography is fairly standard. I was able to generate bibtex citations off <https://scholar.google.com>. I then copy and pasted them into my ref.bib file and at the end of my document included a \bibliography{ref} call. I also needed to specify a style (before the bibliography tag). I used `\bibliographystyle{unsrturl}`, which looked fine.
