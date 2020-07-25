nnoremap <F12> :Gstatus <CR>
nnoremap <F10> :Gdiff <CR>

nnoremap <Leader>gb :Gblame<CR>
nnoremap <space>gp :Gpull<CR>

nnoremap <Leader>gco :call fzf#run({
      \ 'source': 'git branch',
      \ 'sink': function('<sid>read_branch_into_checkout')
      \})<CR>

"
" checkout to branch
"
function! s:read_branch_into_checkout(branch)
  execute 'G checkout'.a:branch
endfunction

