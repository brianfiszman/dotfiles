filetype plugin on
filetype plugin indent on
syntax enable

let mapleader = ","

set clipboard=unnamed
set guifont=DroidSansMono\ Nerd\ Font\ 11
set encoding=utf-8
set history=700
set fillchars+=stl:\ ,stlnc:\
set mouse=a
set pastetoggle=<F2>
set hidden
set nowrap
set hlsearch
set incsearch
set textwidth=90
set autoindent
set smartindent
set copyindent
set shiftround
set backspace=indent,eol,start
set ai "Auto indent
set si "Smart indent
set ft=nasm
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

set nobackup       "no backup files
set nowritebackup  "only in case you don't want a backup file while editing
set noswapfile     "no swap files

set t_Co=256
silent! call repeat#set("\<Plug>MyWonderfulMap", v:count)
silent! helptags ALL

let &runtimepath.=',~/.vim/bundle/neoterm'

