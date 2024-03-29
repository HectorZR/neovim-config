" OPTIONS
let g:snips_author = "Hector Zurga"
set title
set titlestring=%F

set number
set relativenumber
set ruler
set noshowmode
set noswapfile
set updatetime=300
set showtabline=2
set autoread
set termguicolors

set ignorecase
set smartcase
syntax on

" General tab size config
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

" Set php tabs size
autocmd Filetype php setlocal tabstop=4
autocmd Filetype php setlocal softtabstop=4
autocmd Filetype php setlocal shiftwidth=4

" Set Python tabs size
autocmd Filetype python setlocal tabstop=4
autocmd Filetype python setlocal softtabstop=4
autocmd Filetype python setlocal shiftwidth=4

set scrolloff=3
set mouse=na
set cursorline " remark current line

set hidden " change buffers without save

set fileencoding=utf-8
set encoding=utf8
set spelllang=en,es

" Ignore certain files and folders when globbing
set wildignore+=*.o,*.obj,*.bin,*.dll,*.exe
set wildignore+=*/.git/*,*/.svn/*,*/__pycache__/*,*/build/**,*/node_modules/*,*/vendor/*,*/coverage/*
set wildignore+=*.pyc
set wildignore+=*.DS_Store
set wildignore+=*.aux,*.bbl,*.blg,*.brf,*.fls,*.fdb_latexmk,*.synctex.gz

" Ask for confirmation on unsaved or read-only files
set confirm
 
" Improve css syntax
autocmd FileType css setlocal iskeyword+=-

" Splitting positions
set splitbelow
set splitright
