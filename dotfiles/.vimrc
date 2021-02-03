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
"Cuz we want faster responses (100ms)
set updatetime=100
"Cuz we a global clipboard (can copy paste with y/p)
set clipboard=unnamed

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

" Languages
Plug 'dougireton/vim-chef'
Plug 'elzr/vim-json'
Plug 'ntpeters/vim-better-whitespace'
Plug 'rhysd/vim-crystal'
Plug 'vim-ruby/vim-ruby'
Plug 'davidhalter/jedi-vim'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'lepture/vim-jinja'
Plug 'hashivim/vim-terraform'
" Autocomplete
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc', { 'do': 'pip3 install pynvim' }
endif
" Other integrations
Plug 'w0rp/ale'
Plug 'itchyny/lightline.vim'
Plug 'maximbaz/lightline-ale'
Plug 'airblade/vim-gitgutter'
" Misc
Plug 'terryma/vim-multiple-cursors'
Plug 'preservim/tagbar'

call plug#end()

" ------------
" Language configs
" ------------
"Cuz syntax highlighting and auto code
syntax on
filetype on
filetype plugin on
filetype indent on

"Cuz default detection is not enough
au BufNewFile,BufRead *.sls set filetype=yaml
au BufNewFile,BufRead Jenkinsfile setf groovy
" --------------
" Neocomplete configs
" --------------
let g:deoplete#enable_at_startup = 1

" https://github.com/fatih/vim-go/blob/3a8e3f6ded412b25fb3c13eecf76d5809fa175e8/doc/vim-go.txt#L147
" python regex stolen from jedi-vim
set completeopt+=noselect
call deoplete#custom#var('omni', 'input_patterns', {
      \  'go': '[^. *\t]\.\w*',
      \  'c': '[^.[:digit:] *\t]\%(\.\|->\)\w*',
      \  'cpp': '[^.[:digit:] *\t]\%(\.\|->\)\w*\|\h\w*::\w*',
      \  'python': '[^. \t0-9]\.\w*$|^\s*@\w*$|^\s*from\s.+import \w*|^\s*from \w*|^\s*import \w*',
      \  'ruby': ['[^. *\t]\.\w*', '[a-zA-Z_]\w*::'],
      \})

"Map tab to completion for tab completion
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"

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
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_extra_types = 1
" We're ok with degraded functionality on older vims
let g:go_version_warning = 0

" ---------------
"  Ale Configs
" ---------------
let g:ale_linters = { 'go': ['go build', 'gofmt', 'golint', 'go vet'] }

" ---------------
" Lightline configs
" ---------------
let g:lightline = {}
" Ale integration
let g:lightline#ale#indicator_warnings = "\U26A0 "
let g:lightline#ale#indicator_errors = "\U2718 "

let g:lightline.component_expand = {
      \  'linter_checking': 'lightline#ale#checking',
      \  'linter_warnings': 'lightline#ale#warnings',
      \  'linter_errors': 'lightline#ale#errors',
      \  'linter_ok': 'lightline#ale#ok',
      \ }
let g:lightline.component_type = {
      \     'linter_checking': 'left',
      \     'linter_warnings': 'warning',
      \     'linter_errors': 'error',
      \     'linter_ok': 'left',
      \ }

" Lightline
let g:lightline.active = { 'right':[[ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_ok'], ['lineinfo'], ['percent'], ['fileformat', 'fileencoding', 'filetype']] }

" Source local vimrc
let $LOCAL_VIMRC = '~/.vimrc.local'
if filereadable($LOCAL_VIMRC)
    source $LOCAL_VIMRC
endif
