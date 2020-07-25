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
  call dein#add('roxma/nvim-yarp')
  call dein#add('shougo/unite.vim')
  call dein#add('octol/vim-cpp-enhanced-highlight')
  call dein#add('shirk/vim-gas')
  call dein#add('yuttie/comfortable-motion.vim')
  call dein#add('APZelos/blamer.nvim')
  call dein#add('mbbill/undotree')
  call dein#add('scrooloose/nerdtree')
  call dein#add('scrooloose/nerdcommenter')
  call dein#add('Xuyuanp/nerdtree-git-plugin')
  call dein#add('jsfaint/gen_tags.vim')
  call dein#add('mhinz/vim-startify')
  call dein#add('Valloric/MatchTagAlways')
  call dein#add('chiel92/vim-autoformat')
  call dein#add('w0rp/ale')
  call dein#add('Yggdroot/indentLine')
  call dein#add('tpope/vim-surround')
  call dein#add('luochen1990/rainbow')
  call dein#add('joshdick/onedark.vim')
  call dein#add('ctrlpvim/ctrlp.vim')
  call dein#add('altercation/vim-colors-solarized')
  call dein#add('vim-airline/vim-airline')
  call dein#add('vim-airline/vim-airline-themes')
  call dein#add('majutsushi/tagbar')
  call dein#add('bling/vim-bufferline')
  call dein#add('flazz/vim-colorschemes')
  call dein#add('airblade/vim-gitgutter')
  call dein#add('tpope/vim-fugitive')
  call dein#add('idanarye/vim-merginal')
  call dein#add('godlygeek/tabular')
  call dein#add('ervandew/supertab')
  call dein#add('tpope/vim-repeat')
  call dein#add('mattn/emmet-vim')
  call dein#add('jiangmiao/auto-pairs')
  call dein#add('raimondi/delimitmate')
  call dein#add('vim-scripts/sessionman.vim')
  call dein#add('tpope/vim-commentary')
  call dein#add('nathanaelkane/vim-indent-guides')
  call dein#add('terryma/vim-multiple-cursors')
  call dein#add('sjl/gundo.vim')
  call dein#add('tpope/vim-markdown')
  call dein#add('marcweber/vim-addon-mw-utils')
  call dein#add('tomtom/tlib_vim')
  call dein#add('sheerun/vim-polyglot', {'merged': 0})
  call dein#add('junegunn/fzf', { 'build': './install --all', 'merged': 0 })
  call dein#add('junegunn/fzf.vim', { 'depends': 'fzf' })
  call dein#add('tpope/vim-sensible')
  call dein#add('nvie/vim-flake8')
  call dein#add('klen/python-mode')
  call dein#add('ryanoasis/vim-devicons')
  call dein#add('jacoborus/tender.vim')
  call dein#add('kassio/neoterm')
  call dein#add('mileszs/ack.vim', {
        \ 'if': executable('ag'),
        \ 'on_cmd': ['Ack', 'LAck'],
        \ })


  if !has('nvim')
    call dein#add('roxma/nvim-yarp')
    call dein#add('roxma/vim-hug-neovim-rpc')
  endif

  call dein#end()
  call dein#save_state()
endif
