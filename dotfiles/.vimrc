"Cuz pathogen
execute pathogen#infect()

" ----------------
"  Standard vim configs
" ----------------

"Cuz vi sucks
set nocompatible
"Cuz sometimes the default backspace sux
set backspace=2
"Cuz vim doesn't like zsh
set shell=bash
"Cuz syntax highlighting
syntax on
"Cuz non-retarded tabs
set smarttab
set expandtab
set shiftwidth=2
set tabstop=2
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
set incsearch
"Cuz wanna know line numbers
set ruler
"Cuz default buffer size is too small
set viminfo='20,<1000

" ---------------
" Vim Extras
" ---------------
"Cuz forgetting sudo sucks
cmap w!! w !sudo tee > /dev/null %

"Cuz remembering last line you were on
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif
"Cuz losing undo after closing sux
try
    set undodir=~/.vim/undodir/
    set undofile
catch
endtry

"Cuz autoeverything
filetype on
filetype plugin on
filetype indent on

"Cuz default detection is not enough
au BufNewFile,BufRead *.sls set filetype=yaml
au BufNewFile,BufRead Jenkinsfile setf groovy

" --------------
" Language specific configs
" --------------
" Python
"Cuz built in python highlighting is pretty good
let python_highlight_all = 1

" Golang
"Cuz we want highlighting
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1


" ---------------
" Syntastic Configs
" ---------------
let g:syntastic_check_on_open = 1
let g:syntastic_go_checkers = ['go']

" Source local vimrc
let $LOCAL_VIMRC = '~/.vimrc.local'
if filereadable($LOCAL_VIMRC)
    source $LOCAL_VIMRC
endif
