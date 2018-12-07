let g:LanguageClient_serverCommands = {
      \ 'javascript': ['/usr/bin/javascript-typescript-stdio'],
      \ 'c': ['/usr/bin/ccls'],
      \ 'cpp': ['/usr/bin/ccls'],
      \ 'javascript.jsx': ['tcp://127.0.0.1:2089'],
      \ 'python': ['/usr/bin/pyls'],
      \ 'python2': ['/usr/bin/pyls2'],
      \ }

set omnifunc=LanguageClient#omniComplete      

nnoremap <C-M-k> :call LanguageClient_contextMenu()<CR>
" Or map each action separately
nnoremap <silent> gk :call LanguageClient#textDocument_hover()<CR>
nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
nnoremap <silent> <M-k> :call LanguageClient#textDocument_rename()<CR>
let g:LanguageClient_autoStart = 1
