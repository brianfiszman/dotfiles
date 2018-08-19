" --- NeoTerm ---
let g:neoterm_default_mod='tab'
let g:neoterm_automap_keys=',tp'
let g:neoterm_repl_ruby='pry'
let g:neoterm_repl_python='ipython'
let g:neoterm_autoinsert = 1
let g:neoterm_size = 10 

" :botright for horizontal, vertical for... :v
nnoremap <C-t> :botright Ttoggle<CR>
inoremap <C-t> <esc>:botright Ttoggle<CR>
tnoremap <C-t> <C-\><C-n>:botright Ttoggle<CR>

nnoremap <silent> <Leader>tv :vertical Ttoggle<CR>
inoremap <silent> <Leader>tv <esc>:vertical Ttoggle<CR>
tnoremap <C-t> <C-\><C-n>:vertical Ttoggle<CR>

tnoremap <esc> <C-\><C-n>

