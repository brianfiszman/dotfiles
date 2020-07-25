augroup fzf_preview
  autocmd!
  autocmd User fzf_preview#initialized call s:fzf_preview_settings()
augroup END

function! s:fzf_preview_settings() abort
  let g:fzf_preview_command = 'COLORTERM=truecolor ' . g:fzf_preview_command
  let g:fzf_preview_grep_preview_cmd = 'COLORTERM=truecolor ' . g:fzf_preview_grep_preview_cmd
endfunction

let g:fzf_preview_lines_command = 'bat --color=always --plain --number' " Installed bat
let g:fzf_preview_command = 'bat --color=always --plain {-1}'
let g:fzf_preview_filelist_command = 'rg --files --hidden --follow --no-messages -g \!"* *"' " Installed ripgrep
let g:fzf_preview_use_dev_icons = 1
nnoremap <c-p> :CocCommand fzf-preview.GitFiles<CR>
nnoremap <Leader>gl :Commits<CR>
nnoremap <Leader>gf :BCommits<CR>
nnoremap <Space>gl :CocCommand fzf-preview.GitLogs<CR>
nnoremap <Space>gb :CocCommand fzf-preview.GitBranches<CR>


