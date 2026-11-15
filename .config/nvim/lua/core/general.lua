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

-- Reindent before the native edit command. For nvim-treesitter, use its
-- line-number API directly: running the Normal-mode == operator can move the
-- cursor asynchronously while the parser refreshes the edited tree.
local scope_indent_group = vim.api.nvim_create_augroup("DotfilesScopeIndent", {
  clear = false,
})

local function reindent_current_line(lnum)
  local indentexpr = vim.bo.indentexpr
  if indentexpr == "nvim_treesitter#indent()" then
    print(("[scope-indent] before get_indent row=%d cursor=%s"):format(
      lnum, vim.inspect(vim.api.nvim_win_get_cursor(0))))
    local ok, indent = pcall(function()
      return require("nvim-treesitter.indent").get_indent(lnum)
    end)
    print(("[scope-indent] after get_indent ok=%s indent=%s cursor=%s"):format(
      tostring(ok), tostring(indent), vim.inspect(vim.api.nvim_win_get_cursor(0))))
    if ok and type(indent) == "number" and indent >= 0 then
      local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
      local old_indent = line:match("^%s*") or ""
      local body = line:sub(#old_indent + 1)
      vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, {
        string.rep(" ", indent) .. body,
      })
      print(("[scope-indent] after set_lines row=%d cursor=%s"):format(
        lnum, vim.inspect(vim.api.nvim_win_get_cursor(0))))
      return string.rep(" ", indent)
    end
  end

  -- Other indentation engines retain Neovim's native == behavior.
  vim.cmd.normal({
    args = { "==" },
    bang = true,
  })
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
  return line:match("^%s*") or ""
end

local function reindent_and_edit(key)
  local count = vim.v.count1
  local source_cursor = vim.api.nvim_win_get_cursor(0)
  local source_row = source_cursor[1]
  local source_line_before = vim.api.nvim_get_current_line()
  local source_old_indent = source_line_before:match("^%s*") or ""
  local source_indent

  if key == "S" then
    vim.cmd.normal({
      args = { ("%d=="):format(count) },
      bang = true,
    })
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
  source_indent = reindent_current_line(source_row)

  -- Rewriting the source line preserves its row, but restore its exact cursor
  -- offset in case the indentation width changed.
  local current_line = vim.api.nvim_buf_get_lines(0, source_row - 1, source_row, false)[1] or ""
  local new_indent = current_line:match("^%s*") or ""
  vim.api.nvim_win_set_cursor(0, {
    source_row,
    #new_indent + math.max(source_cursor[2] - #source_old_indent, 0),
  })

  -- Native o/O can let an indentexpr produce a different prefix on the new
  -- blank line. Preserve any comment leader/body, replacing only its leading
  -- whitespace with the prefix computed for the source line above.
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
      print(("[scope-indent] InsertEnter before prefix cursor=%s current=%s source_indent=%q"):format(
        vim.inspect(cursor), vim.inspect(line), source_indent))
      vim.api.nvim_win_set_cursor(0, {
        cursor[1],
        #source_indent + body_column,
      })
      print(("[scope-indent] InsertEnter after prefix cursor=%s line=%s"):format(
        vim.inspect(vim.api.nvim_win_get_cursor(0)), vim.inspect(vim.api.nvim_get_current_line())))
    end,
    desc = "Apply the source indentation to a newly opened line",
  })

  local keys = vim.api.nvim_replace_termcodes(
    ("%d%s"):format(count, key),
    true,
    false,
    true
  )
  vim.api.nvim_feedkeys(keys, "int", false)
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
