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
  call dein#add('ncm2/ncm2')
  call dein#add('roxma/nvim-yarp')
  call dein#add('ncm2/ncm2-bufword')
  call dein#add('ncm2/ncm2-path')
  call dein#add('ncm2/ncm2-pyclang')
  call dein#add('ncm2/ncm2-ultisnips')
  call dein#add('SirVer/ultisnips')
  call dein#add('ncm2/ncm2-tern',  {'build': 'npm install'})
  call dein#add('phpactor/ncm2-phpactor')
  call dein#add('phpactor/phpactor' ,  {'build': 'composer install', 'for': 'php'})
  call dein#add('ncm2/ncm2-jedi')
  call dein#add('wokalski/autocomplete-flow', { 'build': 'yarn global add flow' })
  call dein#add('Galooshi/vim-import-js')
  call dein#add('shougo/unite.vim')
  call dein#add('octol/vim-cpp-enhanced-highlight')
  call dein#add('shirk/vim-gas')
  call dein#add('mbbill/undotree')
  call dein#add('scrooloose/nerdtree')
  call dein#add('scrooloose/nerdcommenter')
  call dein#add('Xuyuanp/nerdtree-git-plugin')
  call dein#add('jsfaint/gen_tags.vim')
  call dein#add('Valloric/MatchTagAlways')
  call dein#add('chiel92/vim-autoformat')
  call dein#add('stanangeloff/php.vim')
  call dein#add('w0rp/ale')
  call dein#add('Yggdroot/indentLine')
  call dein#add('numirias/semshi', {'build': ':UpdateRemotePlugins'})
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
  call dein#add('easymotion/vim-easymotion')
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
  call dein#add('othree/html5.vim')
  call dein#add('elzr/vim-json')
  call dein#add('pangloss/vim-javascript')
  call dein#add('sheerun/vim-polyglot')
  call dein#add('junegunn/fzf', { 'build': './install --all', 'rtp': '' })
  call dein#add('junegunn/fzf.vim', { 'depends': 'fzf' })
  call dein#add('othree/javascript-libraries-syntax.vim')
  call dein#add('mxw/vim-jsx')
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

  call dein#add('carlitux/deoplete-ternjs', { 'build': 'yarn global add tern' })
  call dein#add('autozimu/LanguageClient-neovim', {
        \ 'rev': 'next',
        \ 'build': 'bash install.sh',
        \ })

  if !has('nvim')
    call dein#add('roxma/nvim-yarp')
    call dein#add('roxma/vim-hug-neovim-rpc')
  endif

  call dein#end()
  call dein#save_state()
endif
