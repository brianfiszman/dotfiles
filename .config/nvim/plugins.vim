"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state('~/.cache/dein')
  call dein#begin('~/.cache/dein')

  " Let dein manage dein
  " Required:
  call dein#add('~/.cache/dein/repos/github.com/Shougo/dein.vim')

  " Add or remove your plugins here:
  call dein#add('neoclide/coc.nvim', {'merged':0, 'rev': 'release'})
  call dein#add('ryanoasis/powerline-extra-symbols')
  call dein#add('shougo/unite.vim')
  call dein#add('yuttie/comfortable-motion.vim')
  " call dein#add('APZelos/blamer.nvim')
  call dein#add('nvim-tree/nvim-tree.lua')
  call dein#add('nvim-tree/nvim-web-devicons')
  call dein#add('nvim-treesitter/nvim-treesitter', {'hook_post_update': 'TSUpdate'})
  call dein#add('norcalli/nvim-colorizer.lua')
  call dein#add('scrooloose/nerdcommenter')
  call dein#add('jsfaint/gen_tags.vim')
  call dein#add('mhinz/vim-startify')
  call dein#add('Valloric/MatchTagAlways')
  call dein#add('chiel92/vim-autoformat')
  call dein#add('lukas-reineke/indent-blankline.nvim')
  call dein#add('tpope/vim-surround')
  call dein#add('luochen1990/rainbow')
  call dein#add('navarasu/onedark.nvim')
  call dein#add('altercation/vim-colors-solarized')
  call dein#add('glepnir/galaxyline.nvim')
  call dein#add('majutsushi/tagbar')
  call dein#add('godlygeek/tabular')
  call dein#add('ervandew/supertab')
  call dein#add('tpope/vim-repeat')
  call dein#add('mattn/emmet-vim')
  call dein#add('jiangmiao/auto-pairs')
  call dein#add('raimondi/delimitmate')
  call dein#add('vim-scripts/sessionman.vim')
  call dein#add('tpope/vim-commentary')
  call dein#add('terryma/vim-multiple-cursors')
  call dein#add('tpope/vim-markdown')
  call dein#add('sheerun/vim-polyglot', {'merged': 0})
  call dein#add('junegunn/fzf', { 'build': './install --all', 'merged': 0 })
  call dein#add('junegunn/fzf.vim', { 'depends': 'fzf' })
  call dein#add('tpope/vim-sensible')
  call dein#add('jacoborus/tender.vim')
  call dein#add('kassio/neoterm')
  call dein#add('windwp/nvim-ts-autotag')
  call dein#add('p00f/nvim-ts-rainbow')
  call dein#add('mileszs/ack.vim', {
        \ 'if': executable('ag'),
        \ 'on_cmd': ['Ack', 'LAck'],
        \ })
  " DEBUGGER
  call dein#add("mfussenegger/nvim-dap")
  call dein#add("rcarriga/nvim-dap-ui")
  call dein#add("akinsho/bufferline.nvim")

  call dein#add('stevearc/overseer.nvim')
  call dein#add("antoinemadec/FixCursorHold.nvim")
  call dein#add("vim-test/vim-test")
  call dein#add("nvim-neotest/neotest")
  call dein#add("nvim-neotest/neotest-plenary")
  call dein#add("nvim-neotest/neotest-vim-test")
  call dein#add("nvim-neotest/neotest-go")
  call dein#add("haydenmeade/neotest-jest")
  call dein#add('nvim-lua/plenary.nvim')

  call dein#add("fatih/vim-go")


  " Database stuff
  call dein#add("tpope/vim-dadbod")
  call dein#add("kristijanhusak/vim-dadbod-ui")


  call dein#add("rcarriga/nvim-notify")

  call dein#add('lewis6991/gitsigns.nvim')
  call dein#add('tpope/vim-fugitive')

  if !has('nvim')
    call dein#add('roxma/nvim-yarp')
    call dein#add('roxma/vim-hug-neovim-rpc')
  endif

  call dein#add('coreyja/fzf.devicon.vim')

  call dein#end()
  call dein#save_state()
endif
