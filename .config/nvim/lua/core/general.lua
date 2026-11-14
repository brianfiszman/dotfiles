local map = vim.api.nvim_set_keymap

-- Mappings
map('n', '<Space>', '', {})
vim.g.mapleader = ' '
vim.cmd([[
let $NVIM_TUI_ENABLE_TRUE_COLOR=1
set re=0
set shell=/bin/zsh
let $SHELL = "/bin/zsh"
let $FZF_PREVIEW_PREVIEW_BAT_THEME = 'ansi-dark'

set ignorecase
set nocompatible
set conceallevel=3
set guifont=FiraCode\ Nerd\ Font:h11
set history=700
set fillchars+=stl:\ ,stlnc:\
set mouse=a
set hidden
set nowrap
set hlsearch
set incsearch
set textwidth=120
set autoindent
set smartindent
set copyindent
set shiftround
set backspace=indent,eol,start
set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines
set tabstop=2
set softtabstop=2
set numberwidth=2
set expandtab
set shiftwidth=2 smarttab
set smarttab
set number
set showcmd
set cursorline
set wildmenu
" set lazyredraw
set showmatch
set foldenable
set ruler
set foldmethod=syntax
set clipboard=unnamedplus
set ttyfast                                 " terminal acceleration

set nobackup       "no backup files
set nowritebackup  "only in case you don't want a backup file while editing
set noswapfile     "no swap files

filetype plugin on
filetype plugin indent on
syntax on

set encoding=utf-8


let g:ackprg = 'ag --vimgrep'

let g:comfortable_motion_no_default_key_mappings = 1

let g:db_ui_auto_execute_table_helpers = 1
let g:cursorhold_updatetime = 100


" Use a blinking upright bar cursor in Insert mode, a blinking block in normal
if &term == 'xterm-256color' || &term == 'xterm-kitty'|| &term == 'screen-256color' || &term == 'xterm-termite' || &term == 'tmux-256color'
  let &t_SI = "\<Esc>[5 q"
  let &t_EI = "\<Esc>[1 q"
endif

if exists('$TMUX')
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
endif
set tags=tags

let g:blamer_enabled = 1
let g:blamer_delay = 500

" Delete buffer
nmap <silent> <leader>d :bp\|bd! #<CR>
]])

-- Neovim core has no helm filetype detection; helm_ls, the helm treesitter
-- parser and conform's helm entry all key off it
vim.filetype.add({
  pattern = {
    ['.*/templates/.*%.ya?ml'] = 'helm',
    ['.*/templates/.*%.tpl'] = 'helm',
    ['helmfile.*%.ya?ml'] = 'helm',
  },
})

vim.opt.pumheight = 10 -- pop up menu height
vim.opt.pumblend = 10
vim.g.netrw_banner = 0
vim.g.netrw_mouse = 2
vim.g.lsp_handlers_enabled = true
vim.g.codelens_enabled = true
vim.g.cmp_enabled = true

-- Recalculate the current line's indentation before entering an editing
-- command. Queue the original command without remapping so the built-in
-- insert/change behavior still owns the actual text editing and mode switch.
local function reindent_current_line(count)
  vim.cmd.normal({ args = { ("%d=="):format(count) }, bang = true })
end

local function feed_builtin_normal(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "nx", false)
end

vim.keymap.set("n", "S", function()
  local count = vim.v.count1
  reindent_current_line(count)
  feed_builtin_normal(("%dcc"):format(count))
end, {
  desc = "Reindent and replace line(s)",
  silent = true,
})

for key, description in pairs({
  o = "Reindent and open line below",
  O = "Reindent and open line above",
}) do
  vim.keymap.set("n", key, function()
    local count = vim.v.count1
    reindent_current_line(1)
    feed_builtin_normal(("%d%s"):format(count, key))
  end, {
    desc = description,
    silent = true,
  })
end

