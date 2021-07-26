let g:ultest_use_pty = 1

augroup UltestRunner
    au!
    au BufWritePost * UltestNearest
augroup END
