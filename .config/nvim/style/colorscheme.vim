source ~/.config/nvim/style/airline.vim
source ~/.config/nvim/style/devicons.vim

let g:indentLine_setColors = 1
let g:onedark_terminal_italics = 1
let g:onedark_terminal_bold = 1
let g:solarized_termtrans = 1
let g:solarized_bold = 1
let g:solarized_underline = 1
let g:solarized_italic = 1
let g:solarized_termcolors = 256
let g:rainbow_active = 1

colorscheme space-vim-dark
set background=dark

"For Neovim > 0.1.5 and Vim > patch 7.4.1799 < https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162 >
"Based on Vim patch 7.4.1770 (`guicolors` option) < https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd >
" < https://github.com/neovim/neovim/wiki/Following-HEAD#20160511 >
if (has("termguicolors"))
  set termguicolors
endif

hi Normal guibg=NONE ctermbg=NONE
