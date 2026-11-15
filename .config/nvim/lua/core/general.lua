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
local function get_source_indent(lnum)
  local indentexpr = vim.bo.indentexpr
  if indentexpr == "nvim_treesitter#indent()" then
    local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
    local existing_indent = line:match("^%s*") or ""
    local ok, indent = pcall(function()
      return require("nvim-treesitter.indent").get_indent(lnum)
    end)
    if ok and type(indent) == "number" and indent >= 0 then
      -- Do not rewrite the source line here. Changing it triggers another
      -- parser update before native o/O has consumed the current cursor.
      return string.rep(" ", indent)
    end
    -- Treesitter returns -1 for @indent.auto (for example, comment lines):
    -- retain the source prefix and let native autoindent preserve it.
    return existing_indent
  end

  -- Other indentation engines retain Neovim's native == behavior.
  vim.cmd.normal({
    args = { "==" },
    bang = true,
  })
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
  return line:match("^%s*") or ""
end

local function restore_source_cursor(cursor, reason)
  local line_count = vim.api.nvim_buf_line_count(0)
  local row = math.min(cursor[1], line_count)
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
  local restored = { row, math.min(cursor[2], #line) }
  local before = vim.api.nvim_win_get_cursor(0)
  if before[1] ~= restored[1] or before[2] ~= restored[2] then
    print(("[scope-indent] restoring source cursor after %s: before=%s target=%s"):format(
      reason, vim.inspect(before), vim.inspect(restored)))
  end
  vim.api.nvim_win_set_cursor(0, restored)
end

local scope_indent_group = vim.api.nvim_create_augroup("DotfilesScopeIndent", {
  clear = false,
})

local function reindent_and_edit(key)
  local count = vim.v.count1
  local source_cursor = vim.api.nvim_win_get_cursor(0)
  local source_row = source_cursor[1]
  local source_indent

  if key == "S" then
    vim.cmd.normal({
      args = { ("%d=="):format(count) },
      bang = true,
    })
    restore_source_cursor(source_cursor, "S reindent")
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
  source_indent = get_source_indent(source_row)
  -- Some indentation providers parse/recompute buffer state while answering
  -- a line query. Keep native o/O anchored to the line where the user pressed it.
  restore_source_cursor(source_cursor, key .. " indent calculation")

  local keys = vim.api.nvim_replace_termcodes(
    ("%d%s"):format(count, key),
    true,
    false,
    true
  )
  local winid = vim.api.nvim_get_current_win()
  print(("[scope-indent] schedule native %s count=%d from source cursor=%s source_indent=%q"):format(
    key, count, vim.inspect(vim.api.nvim_win_get_cursor(0)), source_indent))

  -- The current Normal-mode mapping must finish before the native open command
  -- is inserted into typeahead. Dispatching synchronously from this callback
  -- can let the original mapped input and the synthetic key interact.
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(winid)
      or vim.api.nvim_get_current_win() ~= winid
      or vim.api.nvim_win_get_buf(winid) ~= bufnr
    then
      print(("[scope-indent] skipped scheduled %s: source window/buffer changed"):format(key))
      return
    end

    restore_source_cursor(source_cursor, key .. " scheduled dispatch")

    -- TEMPORARY DIAGNOSTICS: trace the exact native-open / Insert lifecycle.
    local trace_group = vim.api.nvim_create_augroup("DotfilesScopeIndentTrace", {
      clear = true,
    })
    local trace_enters, trace_leaves = 0, 0
    local function trace_scope_event(label)
      local cursor = vim.api.nvim_win_get_cursor(winid)
      local line = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1] or ""
      print(("[scope-indent-trace] %s mode=%s enter=%d leave=%d cursor=%s lines=%d indentexpr=%q line=%q"):format(
        label, vim.fn.mode(), trace_enters, trace_leaves, vim.inspect(cursor),
        vim.api.nvim_buf_line_count(bufnr), vim.bo.indentexpr, line))
    end
    vim.api.nvim_create_autocmd("InsertEnter", {
      group = trace_group,
      buffer = bufnr,
      callback = function()
        trace_enters = trace_enters + 1
        trace_scope_event("InsertEnter")
      end,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
      group = trace_group,
      buffer = bufnr,
      callback = function()
        trace_leaves = trace_leaves + 1
        trace_scope_event("InsertLeave")
      end,
    })
    trace_scope_event("before native normal")
    print(("[scope-indent-trace] source options filetype=%q formatoptions=%q autoindent=%s smartindent=%s copyindent=%s"):format(
      vim.bo.filetype, vim.bo.formatoptions, tostring(vim.bo.autoindent),
      tostring(vim.bo.smartindent), tostring(vim.bo.copyindent)))
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({
      event = { "InsertEnter", "InsertLeave" },
      buffer = bufnr,
    })) do
      print(("[scope-indent-trace] autocmd event=%s group=%s desc=%q pattern=%q once=%s command=%q"):format(
        autocmd.event, tostring(autocmd.group_name or autocmd.group),
        tostring(autocmd.desc), tostring(autocmd.pattern),
        tostring(autocmd.once), tostring(autocmd.command)))
    end
    local saved_indentexpr = vim.bo.indentexpr
    -- The Treesitter indentexpr can reposition the native open-line target
    -- while Neovim computes indentation for the newly created blank line.
    -- We already computed the source prefix, so suspend only this expression
    -- while creating the line; restore it in the second InsertEnter callback.
    vim.bo.indentexpr = ""
    print(("[scope-indent] execute native %s count=%d cursor=%s indentexpr=%q"):format(
      key, count, vim.inspect(vim.api.nvim_win_get_cursor(winid)), saved_indentexpr))
    vim.cmd.normal({
      args = { keys },
      bang = true,
    })
    trace_scope_event("after native normal returns")
    -- :normal! opens the line natively, triggers an initial InsertEnter, then
    -- returns to Normal when the Ex command ends. Register after that first
    -- event so this callback runs on the second InsertEnter caused by
    -- startinsert!, immediately before the user can type.
    vim.api.nvim_create_autocmd("InsertEnter", {
      group = scope_indent_group,
      buffer = bufnr,
      once = true,
      callback = function()
        trace_scope_event("prefix callback entered")
        local cursor = vim.api.nvim_win_get_cursor(winid)
        local line = vim.api.nvim_get_current_line()
        local old_indent = line:match("^%s*") or ""
        local body = line:sub(#old_indent + 1)
        local body_column = math.max(cursor[2] - #old_indent, 0)
        vim.api.nvim_buf_set_lines(bufnr, cursor[1] - 1, cursor[1], false, {
          source_indent .. body,
        })
        vim.bo.indentexpr = saved_indentexpr
        trace_scope_event("prefix applied and indentexpr restored")
        print(("[scope-indent] applied prefix and restored indentexpr for %s row=%d indent=%d line=%q"):format(
          key, cursor[1], vim.fn.indent(cursor[1]), vim.api.nvim_get_current_line()))

        -- startinsert! finalizes its cursor placement after InsertEnter. Move
        -- to the end of the restored prefix after that command has completed.
        vim.schedule(function()
          if not vim.api.nvim_win_is_valid(winid)
            or vim.api.nvim_get_current_win() ~= winid
            or vim.api.nvim_win_get_buf(winid) ~= bufnr
            or vim.fn.mode():sub(1, 1) ~= "i"
          then
            return
          end
          local current = vim.api.nvim_win_get_cursor(winid)
          local current_line = vim.api.nvim_get_current_line()
          local indent = current_line:match("^%s*") or ""
          vim.api.nvim_win_set_cursor(winid, { current[1], #indent })
          print(("[scope-indent] positioned cursor for %s row=%d column=%d line=%q"):format(
            key, current[1], vim.api.nvim_win_get_cursor(winid)[2], current_line))
          trace_scope_event("scheduled after startinsert")
          vim.api.nvim_del_augroup_by_id(trace_group)
        end)
      end,
      desc = "Apply the source indentation after native open and Insert restart",
    })
    trace_scope_event("before explicit startinsert")
    vim.cmd("startinsert!")
    trace_scope_event("after explicit startinsert returns")
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
