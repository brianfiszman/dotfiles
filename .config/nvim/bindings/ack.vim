" let g:ackprg = 'rg -S --column --line-number --no-heading --vimgrep --color=always --smart-case'
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>), 1,
  \   fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}), <bang>0)
nnoremap <Leader>a :Rg<CR>
