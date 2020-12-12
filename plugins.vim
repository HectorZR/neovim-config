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
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'easymotion/vim-easymotion' "move faster in a file
Plug 'tpope/vim-surround'
Plug 'majutsushi/tagbar' "need CTags dependency
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb' " required by fugitive to :Gbrowse
Plug 'terryma/vim-multiple-cursors'
Plug 'wakatime/vim-wakatime'

" Server Language
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Javascript Syntax Highlighting
Plug 'mxw/vim-jsx'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'pangloss/vim-javascript'

" Dart Syntax Highlighting
Plug 'dart-lang/dart-vim-plugin'

" Python Syntax Highlighting
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}

" Golang Syntax Highlighting
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

" File Icons
Plug 'ryanoasis/vim-devicons'



" THEMES
Plug 'rafi/awesome-vim-colorschemes'
Plug 'kaicataldo/material.vim'
Plug 'joshdick/onedark.vim'

call plug#end()
