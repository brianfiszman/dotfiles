vim.cmd([[
nnoremap <silent> <C-S-Right> :vertical resize +5<CR>
nnoremap <silent> <C-S-Left> :vertical resize -5<CR>
nnoremap <silent> <C-S-Up> :res -1<CR>
nnoremap <silent> <C-S-Down> :res +1<CR>
nnoremap <silent> <C-S-Up> :res -1<CR>
nnoremap <silent> <C-S-Down> :res +1<CR>
nnoremap <silent> <leader>d :bp\|bd! #<CR>
nnoremap <c-c> :close <CR>
nnoremap <S-A-Left> :bp<CR>
nnoremap <S-A-Right> :bn <CR>
]])
