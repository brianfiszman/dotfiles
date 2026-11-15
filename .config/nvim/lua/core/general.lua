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

-- Reindent the current scope, then use Neovim's native editing command.
-- The temporary indentexpr override lets autoindent copy the computed prefix
-- from the source line; restore the original engine before the user can type.
local scope_indent_group = vim.api.nvim_create_augroup("DotfilesScopeIndent", {
  clear = false,
})

local function reindent_and_edit(key)
  local count = vim.v.count1
  local reindent_count = key == "S" and count or 1
  local source_cursor = vim.api.nvim_win_get_cursor(0)

  vim.cmd.normal({
    args = { ("%d=="):format(reindent_count) },
    bang = true,
  })

  if key == "S" then
    -- The native change-line command preserves the indentation computed above.
    local keys = vim.api.nvim_replace_termcodes(
      ("%dS"):format(count),
      true,
      false,
      true
    )
    vim.api.nvim_feedkeys(keys, "int", false)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local source_line = vim.api.nvim_get_current_line()
  vim.api.nvim_win_set_cursor(0, {
    source_cursor[1],
    math.min(source_cursor[2], #source_line),
  })
  source_line = vim.api.nvim_get_current_line()
  local source_indent = source_line:match("^%s*") or ""

  -- Native o/O may create a line with an indentexpr result that differs from
  -- its source line. Preserve its comment leader/content, but replace only
  -- leading whitespace on InsertEnter with the source line's computed prefix.
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = scope_indent_group,
    buffer = bufnr,
    once = true,
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line = vim.api.nvim_get_current_line()
      local old_indent = line:match("^%s*") or ""
      local body = line:sub(#old_indent + 1)
      local body_column = math.max(cursor[2] - #old_indent, 0)

      vim.api.nvim_buf_set_lines(0, cursor[1] - 1, cursor[1], false, {
        source_indent .. body,
      })
      vim.api.nvim_win_set_cursor(0, {
        cursor[1],
        #source_indent + body_column,
      })
    end,
    desc = "Apply the reindented source prefix to a newly opened line",
  })

  -- Treesitter may schedule cursor bookkeeping after ==. Re-anchor and
  -- enqueue the native open command on the next event-loop turn, after that
  -- bookkeeping has completed. Insert the keys at the front so fast user input
  -- cannot overtake the mapping's native edit.
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr then
      return
    end
    vim.api.nvim_win_set_cursor(0, {
      source_cursor[1],
      math.min(source_cursor[2], #source_line),
    })
    local keys = vim.api.nvim_replace_termcodes(
      ("%d%s"):format(count, key),
      true,
      false,
      true
    )
    vim.api.nvim_feedkeys(keys, "int", false)
  end)
end

vim.keymap.set("n", "S", function()
  reindent_and_edit("S")
end, {
  desc = "Reindent and replace line(s)",
  silent = true,
})

for key, description in pairs({
  o = "Reindent and open line below",
  O = "Reindent and open line above",
}) do
  vim.keymap.set("n", key, function()
    reindent_and_edit(key)
  end, {
    desc = description,
    silent = true,
  })
end
