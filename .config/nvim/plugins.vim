"dein Scripts-----------------------------
if &compatible
    set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=/home/brian/.cache/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state('/home/brian/.cache/dein')
    call dein#begin('/home/brian/.cache/dein')

    " Let dein manage dein
    " Required:
    call dein#add('/home/brian/.cache/dein/repos/github.com/Shougo/dein.vim')

    " Add or remove your plugins here:
    call dein#add('Shougo/deoplete.nvim')
    call dein#add('shougo/neosnippet.vim')
    call dein#add('shougo/neosnippet-snippets')
    call dein#add('wokalski/autocomplete-flow')
    call dein#add('shougo/unite.vim')
    call dein#add('shougo/deoplete.nvim')
    call dein#add('octol/vim-cpp-enhanced-highlight')
    call dein#add('shirk/vim-gas')
    call dein#add('mbbill/undotree')
    call dein#add('scrooloose/nerdtree')
    call dein#add('scrooloose/nerdcommenter')
    call dein#add('Xuyuanp/nerdtree-git-plugin')
    call dein#add('jsfaint/gen_tags.vim')
    call dein#add('chiel92/vim-autoformat')
    call dein#add('tpope/vim-fugitive')
    call dein#add('stanangeloff/php.vim')
    call dein#add('w0rp/ale')
    call dein#add('sheerun/vim-polyglot')
    call dein#add('tpope/vim-surround')
    call dein#add('joshdick/onedark.vim')
    call dein#add('kien/ctrlp.vim')
    call dein#add('altercation/vim-colors-solarized')
    call dein#add('vim-airline/vim-airline')
    call dein#add('vim-airline/vim-airline-themes')
    call dein#add('majutsushi/tagbar')
    call dein#add('bling/vim-bufferline')
    call dein#add('flazz/vim-colorschemes')
    call dein#add('airblade/vim-gitgutter')
    call dein#add('easymotion/vim-easymotion')
    call dein#add('godlygeek/tabular')
    call dein#add('ervandew/supertab')
    call dein#add('tpope/vim-repeat')
    call dein#add('mattn/emmet-vim')
    call dein#add('mileszs/ack.vim')
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
    call dein#add('mxw/vim-jsx')
    call dein#add('tpope/vim-sensible')
    call dein#add('nvie/vim-flake8')
    call dein#add('klen/python-mode')
    call dein#add('kassio/neoterm')
    call dein#add('junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' })
    call dein#add('junegunn/fzf.vim')
    if !has('nvim')
        call dein#add('roxma/nvim-yarp')
        call dein#add('roxma/vim-hug-neovim-rpc')
    endif

    call dein#end()
    call dein#save_state()
endif
