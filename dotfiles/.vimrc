"Cuz pathogen
execute pathogen#infect()

"Cuz vi sucks
set nocompatible
"Cuz sometimes the default backspace sux
set backspace=2
"Cuz vim doesn't like zsh
set shell=bash
"Cuz colors
set t_Co=256
"Cuz syntax highlighting
syntax on
"Cuz non-retarded tabs
set smarttab
set expandtab
set shiftwidth=4
set tabstop=4
set autoindent
set smartindent
"set mouse=a
"Cuz remembering vim commands sucks
set wildmenu
"Cuz logical splits
set splitright
set splitbelow
"Cuz it sux cycling through all results
set hlsearch
"Cuz autoeverything
filetype on
filetype plugin on
filetype indent on
set omnifunc=syntaxcomplete#Complete

"Cuz forgetting sudo sucks
cmap w!! w !sudo tee > /dev/null %

"Cuz default buffer size is too small
set viminfo='20,<1000

"Cuz Salt SLS files are yaml files
au BufNewFile,BufRead *.sls set filetype=yaml
"Cuz built in python highlighting is pretty good
let python_highlight_all = 1
