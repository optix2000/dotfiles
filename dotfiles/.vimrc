" ----------------
"  Standard vim configs
" ----------------

"Cuz vi sucks
set nocompatible
"Cuz sometimes the default backspace sux
set backspace=2
"Cuz vim doesn't like zsh
set shell=bash
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
"Cuz wanna always see status
set laststatus=2
"Cuz default buffer size is too small
set viminfo='20,<1000
"Cuz default pattern memory limit is too small
set maxmempattern=100000

"Cuz we don't care about file browser banners
let g:netrw_banner = 0
"Cuz tree browser es best
let g:netrw_liststyle = 3
"Cuz we don't want 50% file browser
let g:netrw_winsize = 25
"Open file on current right pane
let g:netrw_browse_split = 4
"Move cursor to new split (not required due to logical splits above)
let g:netrw_altv = 1


" ---------------
" Vim Extras
" ---------------
"Cuz forgetting sudo sucks
function WriteWithSudo()
  silent execute 'w !sudo tee > /dev/null %'
  if v:shell_error == 0
    silent execute 'e!'
    redraw | echomsg @% 'written as root'
  else
    redraw | echohl ErrorMsg | echomsg @% 'failed to write as root' | echohl None
  endif
endfunction

command W call WriteWithSudo()
cmap w!! W

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

" ----------
" Plugins
"-----------
call plug#begin()

Plug 'dougireton/vim-chef'
Plug 'elzr/vim-json'
Plug 'ntpeters/vim-better-whitespace'
Plug 'w0rp/ale'
Plug 'vim-ruby/vim-ruby'
Plug 'davidhalter/jedi-vim'
Plug 'nsf/gocode', { 'rtp': 'vim', 'do': '~/.vim/plugged/gocode/vim/symlink.sh' }
Plug 'fatih/vim-go'
Plug 'Shougo/neocomplete'

call plug#end()

" ------------
" Language configs
" ------------
"Cuz syntax highlighting and auto code
syntax on
filetype on
filetype plugin on
filetype indent on
"Enable neocomplete
let g:neocomplete#enable_at_startup = 1
"Enable ruby autocompletetion, with only omni (neo omni is broken)
if !exists('g:neocomplete#force_omni_input_patterns')
  let g:neocomplete#force_omni_input_patterns = {}
endif
let g:neocomplete#force_omni_input_patterns.ruby = '[^. *\t]\.\w*\|\h\w*::'
"Enable golang autocompletion
if !exists('g:neocomplete#sources#omni#input_patterns')
  let g:neocomplete#sources#omni#input_patterns = {}
endif
let g:neocomplete#sources#omni#input_patterns.go = '[^.[:digit:] *\t]\.\w*'

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
