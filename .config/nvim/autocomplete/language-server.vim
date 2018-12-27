let g:LanguageClient_serverCommands = {
      \ 'javascript': ['javascript-typescript-stdio'],
      \ 'c': ['/usr/bin/ccls'],
      \ 'cpp': ['/usr/bin/ccls'],
      \ 'javascript.jsx': ['javascript-typescript-stdio'],
      \ 'python': ['/usr/bin/pyls'],
      \ 'python2': ['/usr/bin/pyls2'],
      \ }

set omnifunc=LanguageClient#omniComplete      
set completefunc=LanguageClient#complete

nnoremap <C-M-k> :call LanguageClient_contextMenu()<CR>
" Or map each action separately
nnoremap <silent> gk :call LanguageClient#textDocument_hover()<CR>
nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
nnoremap <silent> <M-k> :call LanguageClient#textDocument_rename()<CR>
let g:LanguageClient_autoStart = 1
