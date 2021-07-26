let g:airline#extensions#tabline#enabled = 1
let g:airline_theme = 'deus'
let g:deus_termcolors=256
let g:airline#extensions#tagbar#enabled = 1
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#fugitiveline#enabled = 1
let g:airline#extensions#bufferline#enabled = 1
let g:airline_powerline_fonts = 1
" let g:airline_theme = 'onedark'

" testing rounded separators (extra-powerline-symbols):
let g:airline_left_sep = "\uE0C0"
let g:airline_right_sep = "\uE0C7"
" set the CN (column number) symbol:
let g:airline_section_z = airline#section#create(["\uE0A1" . '%{line(".")}' . "\uE0A3" . '%{col(".")}'])
" let g:airline_section_c = airline#section#create(['%n: %t'])
