" Press enter key to trigger snippet expansion
" The parameters are the same as `:help feedkeys()`
set shortmess+=c
inoremap <silent> <expr> <CR> pumvisible() ?
            \ncm2_ultisnips#expand_or("\<CR>", 'n') : "\<CR>"
let g:UltiSnipsJumpForwardTrigger	= "<c-j>"
let g:UltiSnipsJumpBackwardTrigger	= "<c-k>"
let g:UltiSnipsRemoveSelectModeMappings = 0
