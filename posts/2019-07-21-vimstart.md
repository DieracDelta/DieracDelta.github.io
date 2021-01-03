---
author:
  name: "Justin Restivo"
date: 2019-07-21
linktitle: VimStart
title: Getting Started With (neo)vim
type:
- post
- posts
weight: 10
series:
- vim
aliases:
- /blog/vim_start
---

## What is vim and why should I use it? ##

EDIT: my messy dots are [HERE](https://gitea.justinrestivo.me/jrestivo/neovim_dots/src/branch/master/init.vim)

I've had people approach me and ask how to get started with vim. Based on my struggles with it, I've decided to write a guide describing my workflow. I ran through vimtutor four years ago, switched to and used spacemacs for about two years, then within the past year switched back to (neo)vim.

First of all, I've gone with neovim. Neovim is basically vim but with nice async apis that you can play around with in languages other than vimscript (which is gross), like python or golang. From a user standpoint, you shouldn't observe any visible differences. (EDIT: compiling head of neovim brings in a nice hover feature worth using)

Now, let's get started. What is vim and why use it? Vim is a modal editor, meaning that it supports different modes one may switch between. It makes for speedier text manipulation than the more traditional editor (e.g. microsoft word) in multiple ways. This part isn't as interesting to me, so I won't spend anymore time on it. Go run through vimtutor then come back. I'll write the rest of this assuming you're convinced that vim is a useful tool and want to use it for writing code. I'll talk about ways I've optimized my workflow through vim. Mostly this is an aggregation of stack overflow posts and other blog posts.

## Writing a config file for vim ##


So, first, vim has a config file. Typically it's stored in `$HOME/.vimrc`. However, I'm going to: 

- Assume you're using neovim (though most of what I say will work for vim8)
- Assume you've created a `$HOME/.config/nvim` folder.


Neovim will read from this folder. Within this folder, create a nvim.init file. This will be the equivalent of `$HOME/.vimrc`.

So the first thing I did was lean on others config files. [Isaac Morneau's](https://github.com/isaacmorneau/dotfiles/blob/master/.vim/vimrc)'s config is amazing, and I think a fantastic starting point (this is where I started.) I'll give a high level overview of what's going on in his config. I won't go into the details--a lot of the config options are really good and well commented. You should run through and pick and choose what you want from that. I ended up changing plugins and bindings (post line 94), and this is what I'll spend most of my time talking about. On the first 100 lines or so, we've got a bunch of way saner defaults. Seriously, I can't live without things like wrap, syntax highlighting, line numbers, system-wide clipboard etc. Go through and copy and paste the stuff you want into your config. Don't be daunted by this. Just make sure each addition does what you want.

## managing buffers, windows, and tabs with leader key ##

I'll talk a bit about how things work behind the scenes about tab/buffer management. I didn't think this was particularly obvious from the tutorial. Vim has buffers. You can open a file in a buffer. Vim also has tabs. Think of tabs as the same sort of tabs as in your web browser. You can have the same buffer open in multiple tabs, and closing the buffer closes it across all tabs. You can also have multiple buffers open in a single tab. To create a new tab, do `:tabedit`. This might feel confusing but we're about to add some keybinds to make it easier (in fact it's very similar to how spacemacs does it). Oh, and each vim tab can be split into multiple windows.

Vim has a leader key. You press this key, then a key combo to execute some sort of functionality. Coming from spacemacs, I had already internalized a bunch of keybinds based on the spacebar as a leader key. I would also recommend this as the leader key but you could definitely use other keys! To set a leader key, include in your config file:

`let mapleader = "\<SPACE>"`

Now, we can make shortcuts to specific tasks by using the spacebar in a key sequence. See my [config files](https://gitea.justinrestivo.me/jrestivo/neovim_dots/src/branch/master/init.vim) for some examples. Basically, we can make life a bit easier. We can split windows via these key sequences. For example, to do a vertical split, do space+w+v. This means split a window vertically. E.g. the shortcuts are mnemonic. I've included a bunch of them:
```
map <leader>ws :sp<cr> " window split
map <leader>wv :vs<cr> " window split vertical
map <leader>bd :q<cr> " buffer delete 
map <leader>bD :Bclose!<cr> " buffer close
map <leader>wd :q<cr> " window delete
map <leader>bn :tabnext<cr> " next tab
map <leader>bp :tabprevious<cr> " prev tab
map <leader>bN :tabedit<cr> " buffer new
map <leader>wl :wincmd l<cr> " go to right window
map <leader>wj :wincmd j<cr> " go to down window
map <leader>wk :wincmd k<cr> " go to up window
map <leader>wh :wincmd h<cr> " go to left window
map <leader>tv :vsplit<cr> :terminal<cr> A " new terminal in vertical split 
map <leader>ts :split<cr> :terminal<cr> A " new terminal in horizontal split
map <leader>tn :tab term<cr> A " new terminal in new tab
map <leader>gt gt " goto next tab
map <leader>gT gT " goto previous tab
" buffer management
map <leader>bn :bn<cr> " next buffer
map <leader>bp :bp<cr> " previous buffer
```

## Getting started with vim plugin manager ##

The next thing to do is get a plugin manager. Vim has plugins--bits of vimscript that provide a *lot* of additional functionality. There are a lot of plugin managers out there. Isaac recommends [vim-plug](https://github.com/junegunn/vim-plug), and I've had only good experiences with it. It's incredibly simple to set up and use, but I haven't tried others because this one works so well. That being said, vim8 includes its own built-in plugin manager so if you're using vim, you may want to try that out. To install plug, follow the instructions in the README, which is just a curl command in most cases. To use, introduce a section into your config that looks like (again the README's example is great and I'm just re-explaining...):
```
call plug#begin('~/.vim/plugged')
Plug 'github_username/repo_name'
" you can also include configuration settings
"... more plugins
call plug#end()
```

Where you replace `github_username` with a github username and `repo_name` with the name of the plugin repo. Once you've included a plugin, run `:PlugInstall` to install plugins, `:PlugUpdate` to update, and `:PlugClean` to remove previously installed plugins no longer listed in your config file. Easy, right?  I'll now outline some of the more useful plugins (many of which Isaac showed me). 

## Project Management ##

The first plugins I want to discuss are related to project management. When you open a project directory, it's often really annoying to do three things. I'll go through them one by one:

### Project Management ###

It's really annoying to reopen files every time you want to open vim to edit a project (I'm using project to mean a directory). Luckily, my friend Isaac ran into and fixed this problem. He wrote his own [plugin](https://github.com/isaacmorneau/vim-simple-sessions) in vimscript that I strongly recommend you try. In essence, it comes in two parts:

- a bash script to choose between pre-existing sessions.
- some execute mode commands to control how sessions work

The bash script is something to paste into your .bashrc. I edited it (see below) to run in zshell (throw into .zshrc):
```
function nvimp() {
        vcmd=$(command -v nvim &>/dev/null && echo nvim || echo vim)
        vfl="$HOME/.local/share/nvim/session"
        file=$(find $vfl -type f | fzf +m -1)
        if [ -n "$file" ]; then
                vcd=$(grep -m 1 -e 'cd ' "$file")
                eval $vcd
                $vcmd
        fi
}
```

Note that this requires [FZF](https://www.google.com/search?q=fzf&oq=fzf&aqs=chrome..69i57j69i60j0l4.700j0j1&sourceid=chrome&ie=UTF-8) to be installed. Then you can run this script and choose between saved sessions. To use the session, you run create a session with `Smk`, save with `Sss`, or remove with `Srm`. It will also open the session with you open the project directory in vim. This is really convenient for large projects.

## Grep around for keywords and file names ##

This is really helpful when you're looking for something in a project but don't remember the file path. You'll need the two fzf plugins and [Ag](https://github.com/ggreer/the_silver_searcher) for grepping:

```
Plug 'junegunn/fzf' "fuzzy jumping arround
Plug 'junegunn/fzf.vim'
```
Then you can add something akin to:
```
map <leader>bb :Buffers<cr>
map <leader>bl :Lines<cr>
map <leader>bt :BTags<cr>
map <leader>bm :Marks<cr>
```
Triggering one of these will let you type in a phrase and it'll try and match it to either a tag, mark, line, or buffer. Super helpful for code nav. Additionally, using `:Ag` will let you grep the directory.

`nmap <silent> <leader>h :History<cr>` will show recently opened files.

And finally, the kicker is grepping the currently open directory. Do this by calling `:FZF`, or binding it to something (I bound it to the enter key with `map <C-m> :tabedit<cr>:FZF<cr>`).

## Codenav + intellisense ##

Codenav is important for both exploring huge codebases, and double checking that what you're doing is right syntactically. This is typically the perk of using an IDE. But, you can now get VSCode's intellisense and code nav in vim. This is nearly equivalent to Jetbrains IDEs, in my experience. The way that VScode does things (and vim/emacs, now) is via this [language server protocol](https://microsoft.github.io/language-server-protocol/). You'll have a *language server* running in the background, and vim will query it for information that it will then relay to you. Most language servers support async APIs, so you won't experience any latency, even for massive projects. The autocomplete/intellisense engine to use here is [coc.nvim](https://github.com/neoclide/coc.nvim), which does in fact both work with vim and neovim. There are alternatives which I did try, but this is the best on the market as of writing this post.

### Coc.nvim ###

To install, just like any other completion engine, you'll throw the github repo into your list of plugins with Plug (with a bash script: `Plug 'neoclide/coc.nvim', {'do': './install.sh nightly'}`). Then, upon installation, you'll need to choose the languages you're interested in getting completion for. Then, you'll need to do two things:

- Google around for a language server to integrate in, *install this language server separately*, and edit to tell coc.nvim about the language server in its own *separate* config file.
- Google around for coc.nvim support, and `:CocInstall` the relevant plugin.

I'll use C as the example here. First, choose a language server. I like using clangd, and that's what I'll use in this example. Clangd is part of the llvm project and most modern distros have a package that includes it. Note that there are other options such as ccls. Once you've successfully installed (or compiled) clangd, tell coc.nvim about it by including as an [entry](https://github.com/neoclide/coc.nvim/wiki/Language-servers) in your coc config file (accessible via `:CocConfig`):

```
  "languageserver": {
        "clangd": {
              "command": "clangd",
              "args": ["--background-index"],
              "rootPatterns": ["compile_flags.txt", "compile_commands.json", ".vim/", ".git/", ".hg/"],
              "filetypes": ["c", "cpp", "objc", "objcpp"]
            }
  }
```

Note that in the root directory of your project you'll need to write a compile_commands.txt file for clangd to use. This is easy enough to do directly if your c project uses cmake (you can output directly during compilation). Otherwise, if you're using some other build tool (like make), you can use [bear](https://github.com/rizsotto/Bear) to generate this file. You feed bear the command to build the project and bear will both build the project once and autogenerate the compile_commands.txt file. E.g. Something incredibly simple like:
```
bear make 
```

To give you a sense of how powerful this is, I've both used it on my own personal projects (smaller), and absolutely massive projects like qemu. Works like a charm in both cases, surprisingly.

Other language servers of interest (that you can look at my dots to get a sense for):

- python: you'll need to install the language server and jedi things for coc. Google around for that. Should be easy and just copy my config. Fantastic support, though. Makes editing things easy.
- docker: decent support for config files. Again, use google.
- rust: phenomenal support and linting via rls! Coc even installs the language server for you using rustup!
- markdown: good support and linting with efm
- Java: use the [eclipse language server](https://github.com/eclipse/eclipse.jdt.ls)! It's great! Eclipse level autocomplete/intellisense but in vim! There are a few args you have to pass in (see my config file), and obviously you the .jar to be on your path somewhere.
- latex: it's great, but the source of another blog post
- golang: also fantastic support.
- bash: you can grab this but it seems like a bunch of effort...Do you really write enough bash for this to be relevant?

#### shortcuts for coc.nvim ####

See below for the three main things I get out of coc.nvim and how to call them (forall language servers). Note that most of this is in the README.

##### intellisense #####

Depending on the file you've got open, coc.nvim will start a language server at the root directory you've opened. Then, to get autocomplete/intellisense, you'll need to enable sources. Neovim will automatically (or you specify based on file type in the coc config file) and by default enable a bunch of common ones such as a dictionary and words currently in the buffer. I set all of the ones that were not the language server to priority zero so the ended up last in the complete dropdown. To start the complete dropdown, use cntrl+n/p.

##### code nav #####

```
" Manage extensions
nnoremap <silent> <leader>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <leader>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <leader>o  :<C-u>CocList outline<cr>
" Search workleader symbols
nnoremap <silent> <leader>s  :<C-u>CocList -I symbols<cr>
" Resume latest coc list
nnoremap <silent> <leader>p  :<C-u>CocListResume<CR>
" jump to definition using lang server
nmap <silent> <leader>d <Plug>(coc-definition)
" jump to type definition using ls
nmap <silent> <leader>td <Plug>(coc-type-definition)
" jump to implementation using ls
nmap <silent> <leader>i <Plug>(coc-implementation)
" get method or type references using language server
nmap <silent> <leader>r <Plug>(coc-references)
```


###### docs ######
Just as you can use "K" to look at git commit details given a hash, and the man pages for c/bash functions, you can also use "K" to look at the included docs (I've mostly used this for Rust) via this:
```
nnoremap <silent> K :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction
```

##### errors #####

Cycle through errors (denoted diagnostics by coc.nvim) found by the language server via:
```
// all errors
nnoremap <silent> <leader>a  :<C-u>CocList diagnostics<cr>
// cycle
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(con-diagnostic-next)
```

### alternatives ###

Now, there have come times where just straight coc.nvim is good but too much effort to configure. An easier alternative is just tagging for code nav. I also find that this is good as backup in case coc.nvim doesn't have the relevant language sever. Install [exhuberant-ctags](https://github.com/universal-ctags/ctags.git) and ludovicchabant/vim-gutentags. Now, you can use cntrl+] to jump to definition.


## other useful plugins ##

- airblade/vim-gitgutter: tracks git changes
- chrisbra/Colorizer: highlights hex codes
- sheerun/vim-polyglot: fantastic syntax highlighting for almost every language. Doesn't play nice with vim-latex (I'll talk about this later), so include `let g:polyglot_disabled = ['latex']` somewhere.
- vim-syntastic/syntastic for non-language server syntax checking.
- jreybert/vimagit: magit but for vim instead of emacs. This is super helpful for seeing git summaries and diffs from various commits. Also allows for staging/committing from within vim.
- scrooloose/nerdcommenter needed to comment things out based on filetype.
- Raimondi/delimitMate: auto inserted delimiters (e.g. typing '(' will autoinsert ')')


## aesthetics ##

I'll do another blog post on this but I really like what isaac did. Basically you get a status bar on the bottom with vim-airline, and onedark color scheme from vim-airline-themes that you can enable with `colorscheme onedark`. You can also set individual colors and characters (again, see my init.vim).

