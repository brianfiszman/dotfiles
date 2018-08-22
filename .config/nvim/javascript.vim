let g:used_javascript_libs = 'react'

" Enables code folding for javascript based on our syntax file.
augroup javascript_folding
    au!
    au FileType javascript setlocal foldmethod=syntax
augroup END

" prettier-eslint
autocmd FileType javascript set formatprg=prettier-eslint\ --stdi
