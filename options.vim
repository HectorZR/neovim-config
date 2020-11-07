" OPTIONS
let g:snips_author = "Hector Zurga"
set title
set titlestring=%F

set number
set relativenumber
set ruler
set noshowmode
set noswapfile

set gfn=Hack\ NerdFont\ Bold\ 11

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

set scrolloff=3
set mouse=nic
set cursorline " remark current line

set hidden " change buffers without save
" set undofile

set fileencoding=utf-8
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

