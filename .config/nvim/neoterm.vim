" --- NeoTerm ---
let g:neoterm_default_mod='tab'
let g:neoterm_automap_keys=',tp'
let g:neoterm_repl_ruby='pry'
let g:neoterm_repl_python='ipython'
let g:neoterm_repl_node='node'
let g:neoterm_autoinsert = 1
let g:neoterm_autoscroll = 1
let g:neoterm_size = 15

function! ToggleBotRight()
  let g:neoterm_size = 15
  botright Ttoggle
endfunction

function! ToggleVertical()
  let g:neoterm_size = 75 
  vertical Ttoggle
endfunction


" :botright for horizontal, vertical for... :v
nnoremap <C-t> :call ToggleBotRight() <CR>
inoremap <C-t> <esc> :call ToggleBotRight() <CR>
tnoremap <C-t> <C-\><C-n> :call ToggleBotRight() <CR>

nnoremap <silent> <Leader>tv :call ToggleVertical()<CR>
inoremap <silent> <Leader>tv <esc> :call ToggleVertical()<CR>
tnoremap <C-t> <C-\><C-n> :call ToggleVertical()<CR>

tnoremap <esc> <C-\><C-n>

let &runtimepath.=',~/.vim/bundle/neoterm'
