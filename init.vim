"Este es mi vimrc, cualquiera que lo quiera usar es libre de hacerlo, recordar
"que para el funcionamiento de todo esto es necesario el uso del plugin manager
"'Vundle'.
"
"Mi correo es brianezequielfiszman@gmail.com asi que cualquier consulta o
"consejo que se quiera hacer sobre este vimrc puede serme enviada por correo o
"en la seccion de ISSUES de github
"
"
set clipboard=unnamed
set encoding=utf-8
let mapleader = ","
set history=700
" Vundle vimrc
set nocompatible              " be iMproved, required
filetype off                  " required
set laststatus=2
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')
"
"
noremap <C-S-f> :Autoformat<CR>
map <F9> :YcmCompleter FixIt<CR>

let g:ycm_global_ycm_extra_conf = "~/.vim/bundle/YouCompleteMe/third_party/ycmd/cpp/ycm/.ycm_extra_conf.py"
let g:Show_diagnostics_ui = 1
let g:ycm_confirm_extra_conf = 0
let g:ycm_complete_in_comments = 1
let g:ycm_complete_in_strings = 1
let g:ycm_seed_identifiers_with_syntax = 1
let g:ycm_collect_identifiers_from_comments_and_strings = 1
let g:ycm_use_ultisnips_completer = 1
let g:ycm_goto_buffer_command = 'horizontal-split'
let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_autoclose_preview_window_after_insertion = 1
let g:ycm_add_preview_to_completeopt = 1
let g:ycm_key_invoke_completion = '<C-Space>'
let g:ycm_server_use_vim_stdout = 0
let g:ycm_server_keep_logfiles = 1


let g:pymode_rope_lookup_project = 0
let g:pymode_rope = 0
let g:pymode_rope_complete_on_dot = 0

nnoremap <leader>jd :YcmCompleter GoToDefinition<CR>
nnoremap <leader>jd :YcmCompleter GoToDefinitionElseDeclaration<CR>
nnoremap <leader>gd :YcmCompleter GoToDeclaration<CR>


" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'octol/vim-cpp-enhanced-highlight'
Plugin 'davidhalter/jedi-vim'
Plugin 'Valloric/YouCompleteMe'
Plugin 'shirk/vim-gas'
Plugin 'mbbill/undotree'
Plugin 'scrooloose/nerdtree'
Plugin 'chiel92/vim-autoformat'
Plugin 'tpope/vim-fugitive'
Plugin 'stanangeloff/php.vim'
Plugin 'shawncplus/phpcomplete.vim'
Plugin 'scrooloose/syntastic'
Plugin 'tpope/vim-surround'
Plugin 'kien/ctrlp.vim'
Plugin 'altercation/vim-colors-solarized'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'majutsushi/tagbar'
Plugin 'bling/vim-bufferline'
Plugin 'flazz/vim-colorschemes'
Plugin 'scrooloose/nerdcommenter'
Plugin 'airblade/vim-gitgutter'
Plugin 'pangloss/vim-javascript'
Plugin 'easymotion/vim-easymotion'
Plugin 'kchmck/vim-coffee-script'
Plugin 'godlygeek/tabular'
Plugin 'ervandew/supertab'
Plugin 'honza/vim-snippets'
Plugin 'SirVer/ultisnips'
Plugin 'tpope/vim-repeat'
Plugin 'mattn/emmet-vim'
Plugin 'mileszs/ack.vim'
Plugin 'jiangmiao/auto-pairs'
Plugin 'raimondi/delimitmate'
Plugin 'vim-scripts/sessionman.vim'
Plugin 'shougo/unite.vim'
Plugin 'tpope/vim-commentary'
Plugin 'nathanaelkane/vim-indent-guides'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'sjl/gundo.vim'
Plugin 'tpope/vim-markdown'
Plugin 'marcweber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
Plugin 'othree/html5.vim'
Plugin 'elzr/vim-json'
Plugin 'mxw/vim-jsx'
Plugin 'groenewege/vim-less'
"Plugin 'lokaltog/vim-powerline'
Plugin 'tpope/vim-sensible'
Plugin 'nvie/vim-flake8'
Plugin 'xolox/vim-misc'
Plugin 'klen/python-mode'
Plugin 'taglist.vim'
Plugin 'editorconfig/editorconfig-vim'
Plugin 'digitaltoad/vim-jade'



" End configuration, makes the plugins available
call vundle#end()
filetype plugin indent on
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
set tabstop=4
set softtabstop=4
set expandtab
set shiftwidth=4 smarttab
set smarttab
set number
set showcmd
set cursorline
set smartcase
filetype indent on
set wildmenu
set lazyredraw
set showmatch
set foldenable
set ruler


let g:ctrlp_match_window = 'bottom,order:ttb'
let g:ctrlp_switch_buffer = 0
let g:ctrlp_working_path_mode = 0
let g:ctrlp_user_command = 'ag %s -l --nocolor --hidden -g ""'


map <C-e> :NERDTreeToggle<CR>
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'


set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*


let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_cpp_compiler = 'g++'
let g:syntastic_python_flake8_exec = '/usr/bin/python2.7'
let g:syntastic_python_flake8_args = ['-m', 'flake8']
let g:syntastic_python_python_exec = '/usr/bin/python2.7'
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_javascript_eslint_exe = 'npm run lint --'

let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_experimental_simple_template_highlight = 1
let g:cpp_experimental_template_highlight = 1
let g:cpp_concepts_highlight = 1


nmap <F8> :TagbarToggle<CR>
filetype plugin on


" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1
"
" " Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1
"
" " Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'
"
" " Set a language to use its alternate delimiters by default
let g:NERDAltDelims_java = 1
"
" " Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }
"
" " Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1
"
" " Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1


let g:javascript_plugin_jsdoc = 1
let g:javascript_plugin_ngdoc = 1
let g:javascript_plugin_flow = 1
set foldmethod=syntax

let python_highlight_all=1

autocmd FileType python set sw=4
autocmd FileType python set ts=4
autocmd FileType python set sts=4

" Goto definition with F3
map <F3> :YcmCompleter GoTo<CR>

" Open MiniBufExpl with Ctrl-m
map <C-m> :MBEToggle<CR>

" <Leader>f{char} to move to {char}
map  <Leader>f <Plug>(easymotion-bd-f)
nmap <Leader>f <Plug>(easymotion-overwin-f)
"
" " s{char}{char} to move to {char}{char}
nmap s <Plug>(easymotion-overwin-f2)
"
" " Move to line
map <Leader>L <Plug>(easymotion-bd-jk)
nmap <Leader>L <Plug>(easymotion-overwin-line)
"
" " Move to word
map  <Leader>w <Plug>(easymotion-bd-w)
nmap <Leader>w <Plug>(easymotion-overwin-w)


let g:EasyMotion_smartcase = 1
let g:EasyMotion_use_smartsign_us = 1 " US layout

" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<c-j>"
let g:UltiSnipsJumpForwardTrigger="<c-l>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"
"
" " If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

let g:SuperTabDefaultCompletionType = "<C-l>"
set t_Co=256
silent! call repeat#set("\<Plug>MyWonderfulMap", v:count)
syntax on

let g:solarized_termtrans = 1 
let g:solarized_bold = 1 
let g:solarized_underline = 1
let g:solarized_italic = 1
let g:solarized_termcolors=256
syntax enable
set background=dark
colorscheme solarized
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme = 'jellybeans'
