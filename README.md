# NeoVim Personal Configs

These are simple configuration for my neovim editor.

It's fully working on Windows and Linux. Work in progress.

Inspired in [this repo](https://github.com/jdhao/nvim-config)

License MIT.

## Plugins already installed

### General neovim functionalities

'preservim/nerdtree'
'Xuyuanp/nerdtree-git-plugin'
'airblade/vim-gitgutter'
'junegunn/fzf'
'junegunn/fzf.vim'
'tpope/vim-commentary'
'itchyny/lightline.vim'
'mengelbrecht/lightline-bufferline'
'easymotion/vim-easymotion' // move faster in a file
'tpope/vim-surround'
'majutsushi/tagbar' // need CTags dependency
'tpope/vim-fugitive'
'tpope/vim-rhubarb' // required by fugitive to :Gbrowse
'terryma/vim-multiple-cursors'
'wakatime/vim-wakatime'
'editorconfig/editorconfig-vim'

### Server Language to add language linter

'neoclide/coc.nvim'

### Typescript Syntax Highlighting

'HerringtonDarkholme/yats.vim'

### Javascript Syntax Highlighting

'maxmellon/vim-jsx-pretty'
'pangloss/vim-javascript'
'heavenshell/vim-jsdoc'

### Dart Syntax Highlighting

'dart-lang/dart-vim-plugin'

### Flutter plugins

'thosakwe/vim-flutter'

### Kotlin plugins

'udalov/kotlin-vim'

### Python Syntax Highlighting

'numirias/semshi'

### Golang Syntax Highlighting

'fatih/vim-go'

### File Icons

'ryanoasis/vim-devicons'

### THEMES

'rafi/awesome-vim-colorschemes'
'kaicataldo/material.vim'

## Custom Vim Mappings

**mapleader = ' '** // this is space or whatever you want

|      Mapping      | Description                                    |
| :---------------: | ---------------------------------------------- |
|    \<leader>w     | Save current buffer                            |
|    \<leader>q     | Close current buffer                           |
|   \<leader>sou    | Refresh vim configs without closing the editor |
|         y         | Copy in normal mode                            |
|        yy         | Copy a complete line                           |
|         p         | Paste in normal mode                           |
|         d         | Cut text in normal mode                        |
|         H         | Set cursor on first char in line               |
|         L         | Set cursor on last char in line                |
|    \<leader>n     | Clean last search                              |
|      \<alt>k      | Move cursor to split terminal up               |
|      \<alt>j      | Move cursor to split terminal down             |
|      \<alt>h      | Move cursor to split terminal left             |
|      \<alt>l      | Move cursor to split terminal right            |
| \<Leader>\<Left>  | Resize split to left                           |
| \<Leader>\<Right> | Resize split to right                          |
|  \<Leader>\<Up>   | Resize split to up                             |
| \<Leader>\<Down>  | Resize split to down                           |
|      \<Tab>       | Move to next buffer                            |
|  \<shift>\<Tab>   | Move to previous buffer                        |
|    \<leader>o     | New line down                                  |
|    \<leader>O     | New line up                                    |
