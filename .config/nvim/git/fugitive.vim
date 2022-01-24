nnoremap <F12> :Git <CR>
nnoremap <F10> :Gdiff <CR>

nnoremap <Leader>gb :Git blame<CR>
nnoremap <space>gp :Git pull<CR>

nmap <space>kc <Plug>(coc-git-keepcurrent)
nmap <space>ki <Plug>(coc-git-keepincoming)
" navigate conflicts of current buffer
nmap <space>pc <Plug>(coc-git-prevconflict)
nmap <space>ni <Plug>(coc-git-nextconflict)

nnoremap <Leader>gco :call fzf#run({
      \ 'source': 'git branch',
      \ 'sink': function('<sid>read_branch_into_checkout')
      \})<CR>

"
" checkout to branch
"
function! s:read_branch_into_checkout(branch)
  execute 'Git checkout'.a:branch
endfunction
