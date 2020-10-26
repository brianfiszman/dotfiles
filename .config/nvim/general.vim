filetype plugin on
filetype plugin indent on

let mapleader = ","

set guifont=Fire\ Code\ Nerd\ Font\ 11
set encoding=utf-8

set history=700
set fillchars+=stl:\ ,stlnc:\
set mouse=a
set pastetoggle=<F2>
set hidden
set nowrap
set hlsearch
set incsearch
set textwidth=120
set autoindent
set smartindent
set copyindent
set shiftround
set backspace=indent,eol,start
set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines
set tabstop=2
set softtabstop=2
set expandtab
set shiftwidth=2 smarttab
set smarttab
set number
set showcmd
set cursorline
set smartcase
set wildmenu
set lazyredraw
set showmatch
set foldenable
set ruler
set foldmethod=syntax
set laststatus=2

let c_space_errors=1

set nobackup       "no backup files
set nowritebackup  "only in case you don't want a backup file while editing
set noswapfile     "no swap files

filetype plugin on
filetype plugin indent on
syntax enable

set encoding=utf-8

silent! call repeat#set("\<Plug>MyWonderfulMap", v:count)
silent! helptags ALL

let &runtimepath.=',~/.vim/bundle/neoterm'
let g:ackprg = 'ag --vimgrep'

let g:comfortable_motion_no_default_key_mappings = 1
nnoremap <silent> <S-down> :call comfortable_motion#flick(100)<CR>
nnoremap <silent> <S-up> :call comfortable_motion#flick(-100)<CR>
noremap <silent> <ScrollWheelDown> :call comfortable_motion#flick(40)<CR>
noremap <silent> <ScrollWheelUp>   :call comfortable_motion#flick(-40)<CR>
