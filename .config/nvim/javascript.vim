if isdirectory('./node_modules') && isdirectory('./node_modules/prettier')

  let g:coc_global_extensions += ['coc-prettier']
endif

if isdirectory('./node_modules') && isdirectory('./node_modules/eslint')
  let g:coc_global_extensions += ['coc-eslint']
endif

let g:javascript_enable_domhtmlcss = 1

let g:javascript_plugin_jsdoc = 1
let g:javascript_plugin_ngdoc = 1
let g:javascript_plugin_flow = 1

let g:jsx_ext_required = 0
let g:jsx_pragma_required = 0

" Enables code folding for javascript based on our syntax file.
augroup javascript_folding
  au!
  au FileType javascript setlocal foldmethod=syntax
  au FileType javascript.jsx setlocal foldmethod=syntax
  au FileType javascriptreact setlocal foldmethod=syntax
augroup END

" prettier-eslint
autocmd FileType javascript set formatprg=prettier-eslint\ --stdi
autocmd FileType javascript.jsx set formatprg=prettier-eslint\ --stdi
autocmd FileType javascriptreact set formatprg=prettier-eslint\ --stdi

let g:vim_jsx_pretty_colorful_config = 1
let g:formatters_javascriptreact = ['eslint_local', 'jsbeautify_javascript', 'jscs', 'standard_javascript', 'prettier', 'xo_javascript']


