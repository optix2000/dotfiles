"Cuz vi sucks
set nocompatible
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

au BufNewFile,BufRead *.sls set filetype=yaml

"Cuz pathogen
execute pathogen#infect()

"Cuz forgetting sudo sucks
cmap w!! w !sudo tee > /dev/null %
