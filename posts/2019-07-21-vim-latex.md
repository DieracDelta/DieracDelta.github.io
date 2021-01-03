---
author:
  name: "Justin Restivo"
date: 2019-07-21
linktitle: Vim_And_latex
title: Vim and Latex
type:
- post
- posts
weight: 10
series:
- vim
aliases:
- /blog/vim_latex
---

I'll give a brief overview on how to get a decent vim workflow going. I started out with reading [this blog](https://castel.dev/post/lecture-notes-1/), and I strongly recommend you also do this. However, some of the things he suggested I could not get to work. That being said I'll just give an overview of things I enabled, as they are somewhat different than what he's done.

## coc.nvim ##

The first thing I did was grab integration with coc.nvim. This entailed installing the [texlabs language server](https://github.com/latex-lsp/texlab) (see previous blog post), enabling it in the CocConfig file, and installing `lervag/vimtex`. You'll want to add `"coc.source.vimtex": true,` to your config file, and under language servers, add:
```
"latex": {
        "command": "java",
        "args": [
                "-jar",
                "$PATHTOCOMPILERTEXLAB/texlab.jar"
        ],
        // not start server at home directory, since it won't work.
        "ignoredRootPaths": [
                "~"
        ],
        "filetypes": [
                "tex",
                "bib",
                "plaintex",
                "context"
        ]
},
```
And finally get vimtex integration with coc.nvim with `:CocInstall coc-vimtex`.  This will provide syntax checking and auto complete both for functions and references from your bibliography.

## vimtex ##

Next, to configure vimtex:
```
Plug 'lervag/vimtex'
let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0
set conceallevel=1
let g:tex_conceal='abdmg'
let g:vimtex_compiler_latexmk = { 'options' : [ '-pdf', '-pdflatex="xelatex --shell-escape %O %S"', '-verbose', '-file-line-error', '-synctex=1', '-interaction=nonstopmode',  ] }
map <leader>mb :VimtexCompile<cr>
map <leader>mee :VimtexErrors<cr>
autocmd FileType tex setlocal ts=2 sw=2 sts=0 expandtab spell
let g:vimtex_complete_enabled = 1
let g:vimtex_complete_close_braces = 1
let g:vimtex_complete_ignore_case = 1
let g:vimtex_complete_smart_case = 1
let g:vimtex_compiler_progname='nvr'
set spell spelllang=en_us
set spellfile=$HOME/.config/nvim/spell/en.utf-8.add
inoremap <C-l> <c-g>u<Esc>[s1z=`]a<c-g>u
autocmd FileType tex setlocal ts=2 sw=2 sts=0 expandtab spell
```

Let's break this down line by line: 

1) grabs the plugin.

2) Second line says "prefer latex when the filetype isn't known but looks like latex"

3) Third line sets zathura as the pdf viewer of choice for live preview

4) Fourth line disables vimtex's error reporting from popping up when you have errors.

5) Setting the conceal level to something sane

6) enables symbol substitution on lines you are not editing. Super helpful to make the latex readable.

7) compiler options to use xelatex as the default compiler. I got this from a stackoverflow post. It lets you include code in your latex documents with syntax highlighting via minted/pygments. Feel free to comment this out if you don't need it.

8) Vimtex will live recompile for you in zanthura. leader+m+b will toggle that on and off.

9) Vimtex will show you compile errors and warnings when you run leader+m+e+e.

10-13) all sane defaults.

14) You need nvr for the auto compilation.

15) Setting up the spelling dictionary

16) Specifying a custom spell file. You can append to this pretty easily by just hovering over words not in the dictionary and pressing `zG`.

17) Castel's trick for auto spell check. If you mispell a word, press control+l to autofix it based on the dictionary while in insert mode. Super helpful.

18) make the tabs smaller for tex files.


## snippets ##

I almost completely defer to castel's blog here. He did some great stuff with this. The initial configuration is a bit tricky. Snippets basically are programmable pieces of code that you can add in. Great for boilerplate stuff. To be clear, use `SirVer/ultisnips` for the snippet *engine*, and `honza/vim-snippets` for the actual snippets. Additionally, you can include your own in `$HOME/.config/snippets/UltiSnips/$FILETYPE.snippets`. $FILETYPE is the type of file you want--in this case tex, although it may be others. I added a few custom ones. They're fairly straightforward but very useful. For example:
``` latex
snippet bg "\textbf{}" A
\textbf{$1}
endsnippet

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

The former saves you from having to type \textbf whenever you're in normal mode and want a boldface snippet. Same goes for rust. The $1, $2, $3 specify arguments.

To configure triggering the snippets:
```
let g:UltiSnipsExpandTrigger='<c-h>'
let g:UltiSnipsJumpForwardTrigger='<c-h>'
let g:UltiSnipsJumpBackwardTrigger='<c-g>'
let g:UltiSnipsSnippetDirectories=['UltiSnips', '$HOME/.config/nvim/snippets/UltiSnips/']
```

First two lines specifies cntrl+h to expand the snippet and move your cursor to the first argument. Control-g undoes the snippet. And the final line specifies the snippet directory.
