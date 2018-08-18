let g:javascript_enable_domhtmlcss = 1

let g:javascript_plugin_flow = 1
let g:javascript_plugin_jsdoc = 1
let g:javascript_plugin_ngdoc = 1
let g:javascript_plugin_flow = 1

let g:jsx_ext_required = 0

" Enables code folding for javascript based on our syntax file.
augroup javascript_folding
    au!
    au FileType javascript setlocal foldmethod=syntax
augroup END
