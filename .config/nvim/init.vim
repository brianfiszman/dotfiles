let $NVIM_TUI_ENABLE_TRUE_COLOR=1
set re=0
set shell=/bin/zsh
let $SHELL = "/bin/zsh"
let $FZF_PREVIEW_PREVIEW_BAT_THEME = 'ansi-dark'
filetype off

source ~/.config/nvim/plugins.vim
source ~/.config/nvim/general.vim
source ~/.config/nvim/go.vim
source ~/.config/nvim/tab.vim

source ~/.config/nvim/autocomplete/coc.vim

source ~/.config/nvim/matchtag.vim
source ~/.config/nvim/nerdtree.vim
source ~/.config/nvim/emmet.vim
source ~/.config/nvim/ctrlp.vim
source ~/.config/nvim/neoterm.vim

source ~/.config/nvim/git/fugitive.vim

source ~/.config/nvim/cpp.vim
source ~/.config/nvim/javascript.vim
source ~/.config/nvim/python.vim

source ~/.config/nvim/bindings/ack.vim
source ~/.config/nvim/bindings/fzf.vim
source ~/.config/nvim/bindings/splitting.vim

source ~/.config/nvim/tests/ultests.vim

source ~/.config/nvim/debugger/dap.vim

source ~/.config/nvim/style/colorscheme.vim
source ~/.config/nvim/style/bufferline.lua
source ~/.config/nvim/style/galaxyline.lua

noremap <C-f> :Format<CR>
noremap <M-f> :Autoformat<CR>

nmap <F8> :TagbarToggle<CR>

nnoremap <c-c> :close <CR>
nnoremap <S-A-Left> :bp<CR>
nnoremap <S-A-Right> :bn <CR>

" copy and paste
vmap <C-c> "+yi
vmap <C-x> "+c
vmap <C-v> c<ESC>"+p
imap <C-v> <ESC>"+pa

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

" Use a blinking upright bar cursor in Insert mode, a blinking block in normal
if &term == 'xterm-256color' || &term == 'screen-256color' || &term == 'xterm-termite' || &term == 'tmux-256color'
  let &t_SI = "\<Esc>[5 q"
  let &t_EI = "\<Esc>[1 q"
endif

if exists('$TMUX')
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
endif
set tags=tags

let g:blamer_enabled = 1
let g:blamer_delay = 500

" Delete buffer
nmap <silent> <leader>d :bp\|bd! #<CR>

" if exists("g:loaded_webdevicons")
"   call webdevicons#refresh()
" endif
