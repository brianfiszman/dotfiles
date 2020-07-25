let NERDTreeShowHidden=1

let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'
let g:NERDTreeStatusline = ''
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1

let g:NERDTreeGitStatusIndicatorMapCustom = {
      \ "Modified"  : "✹",
      \ "Staged"    : "✚",
      \ "Untracked" : "✭",
      \ "Renamed"   : "➜",
      \ "Unmerged"  : "═",
      \ "Deleted"   : "✖",
      \ "Dirty"     : "✗",
      \ "Clean"     : "✔︎",
      \ 'Ignored'   : '☒',
      \ "Unknown"   : "?"
      \ }

let g:NERDTreeGitStatusUseNerdFonts = 1 " you should install nerdfonts by yourself. default: 0

nnoremap <C-e> :NERDTreeToggle<CR>
nnoremap <silent> <Leader>e :NERDTreeFind<CR>
