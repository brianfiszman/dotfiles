let g:ale_completion_enabled = 1

let g:ale_sign_error = '●' " Less aggressive than the default '>>'
let g:ale_sign_warning = '.'
let g:ale_lint_on_enter = 0 " Less distracting when opening a new file

let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1

let g:ale_fixers = {'javascript': ['prettier', 'eslint'], 'javascript.jsx': ['prettier', 'eslint'], "python": ['pylint', 'pyls']}
let g:ale_linters = {'javascript': ['prettier', 'eslint'], 'javascript.jsx': ['prettier', 'eslint'], "python": ['pylint', 'pyls']}
let g:ale_python_pylint_options = '--load-plugins pylint_django'

nmap <silent> <C-S-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-S-j> <Plug>(ale_next_wrap)
