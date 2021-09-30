let g:vim_plug_fpath = expand(stdpath('data') . '/site/autoload/plug.vim')
if !filereadable(g:vim_plug_fpath)
  if !executable('curl')
    echoerr 'Curl not available on your system, you may install vim-plug by yourself.'
    finish
  endif
  echomsg 'Installing Vim-plug on your system'
  let g:vim_plug_furl = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  silent execute printf('!curl -fLo %s --create-dirs %s', g:vim_plug_fpath, g:vim_plug_furl)
  augroup plug_init
      autocmd!
      autocmd VimEnter * PlugInstall --sync | quit |source $MYVIMRC
  augroup END
endif

let g:PLUGIN_HOME=expand(stdpath('data') . '/plugged')

call plug#begin(g:PLUGIN_HOME)

" GENERAL
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-commentary'
Plug 'itchyny/lightline.vim'
Plug 'akinsho/bufferline.nvim'
Plug 'easymotion/vim-easymotion' "move faster in a file
Plug 'tpope/vim-surround'
Plug 'alvan/vim-closetag'
Plug 'majutsushi/tagbar' "need CTags dependency
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb' " required by fugitive to :Gbrowse
Plug 'terryma/vim-multiple-cursors'
Plug 'wakatime/vim-wakatime'
Plug 'editorconfig/editorconfig-vim'
Plug 'Yggdroot/indentLine'
Plug 'sheerun/vim-polyglot'

" Server Language
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Typescript Syntax Highlighting
Plug 'HerringtonDarkholme/yats.vim'

" Javascript Syntax Highlighting
Plug 'heavenshell/vim-jsdoc', { 
  \ 'for': ['javascript', 'javascript.jsx','typescript'], 
  \ 'do': 'make install'
\}

" Dart Syntax Highlighting
Plug 'dart-lang/dart-vim-plugin'

" Flutter plugins
Plug 'thosakwe/vim-flutter'

" Kotlin plugins
Plug 'udalov/kotlin-vim'

" Python Syntax Highlighting
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}

" Golang Syntax Highlighting
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

" File Icons
Plug 'ryanoasis/vim-devicons'
Plug 'kyazdani42/nvim-web-devicons'

" THEMES
Plug 'rafi/awesome-vim-colorschemes'
Plug 'kaicataldo/material.vim'

call plug#end()
