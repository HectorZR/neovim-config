" ---------------
" PLUGINS OPTIONS
" ---------------

" THEME SELECTION
silent! colorscheme material

" Material theme options
let g:material_theme_style = 'darker-community'
let g:material_terminal_italics = 1

if (has('termguicolors'))
  set termguicolors
endif

" NERDTree options
let NERDTreeQuitOnOpen=1
let g:NERDTreeChDirMode=2
let g:NERDTreeIgnore=['\.rbc$', '\~$', '\.pyc$', '\.db$', '\.sqlite$', '__pycache__']
let g:NERDTreeSortOrder=['^__\.py$', '\/$', '*', '\.swp$', '\.bak$', '\~$']
let g:NERDTreeShowBookmarks=1
let g:nerdtree_tabs_focus_on_files=1
let g:NERDTreeMapOpenInTabSilent = '<RightMouse>'
let g:NERDTreeWinSize = 50

" fzf options
" set wildmode=list:longest,list:full
" set wildignore+=*.o,*.obj,.git,*.rbc,*.pyc,__pycache__,*/node_modules/**,*/vendor/**

if g:is_win
	let $FZF_DEFAULT_COMMAND = "dir /s /b"
else
	let $FZF_DEFAULT_COMMAND =  "find * -path '*/\.*' -prune -o -path '*/vendor/**' -prune -o -path 'node_modules/**' -prune -o -path 'target/**' -prune -o -path 'dist/**' -prune -o  -type f -print -o -type l -print 2> /dev/null"

endif

" vim-airline options
let g:airline_theme='material'
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline#extensions#tagbar#enabled = 1
let g:airline_skip_empty_sections = 1
let g:airline_powerline_fonts = 1

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

if !exists('g:airline_powerline_fonts')
  let g:airline#extensions#tabline#left_sep = ' '
  let g:airline#extensions#tabline#left_alt_sep = '|'
  let g:airline_left_sep          = '▶'
  let g:airline_left_alt_sep      = '»'
  let g:airline_right_sep         = '◀'
  let g:airline_right_alt_sep     = '«'
  let g:airline#extensions#branch#prefix     = '⤴' "➔, ➥, ⎇
  let g:airline#extensions#readonly#symbol   = '⊘'
  let g:airline#extensions#linecolumn#prefix = '¶'
  let g:airline#extensions#paste#symbol      = 'ρ'
  let g:airline_symbols.linenr    = '␊'
  let g:airline_symbols.branch    = '⎇'
  let g:airline_symbols.paste     = 'ρ'
  let g:airline_symbols.paste     = 'Þ'
  let g:airline_symbols.paste     = '∥'
  let g:airline_symbols.whitespace = 'Ξ'
else
  let g:airline#extensions#tabline#left_sep = ''
  let g:airline#extensions#tabline#left_alt_sep = ''

  " powerline symbols
  let g:airline_left_sep = ''
  let g:airline_left_alt_sep = ''
  let g:airline_right_sep = ''
  let g:airline_right_alt_sep = ''
  let g:airline_symbols.branch = ''
  let g:airline_symbols.readonly = ''
  let g:airline_symbols.linenr = ''
endif

" coc plugins autoinstall
" List of coc plugins I use
let g:coc_global_extensions = [
	\ 'coc-phpls',
	\ 'coc-tsserver',
	\ 'coc-html',
	\ 'coc-flutter',
	\ 'coc-go',
	\ 'coc-python',
	\ 'coc-css',
	\ 'coc-markdownlint',
	\ 'coc-json',
	\ 'coc-emmet',
\]
" coc-python options
let g:python_recommended_style = 0 



" ----------------
" PLUGINS MAPPINGS
" ----------------

" NERDTree mappings
map <silent> <leader>m :NERDTreeToggle<CR>

" fzf mappings
" nnoremap <silent> <leader>e :FZF -m<CR>

" easymotion mappings


" tagbar mappings
nmap <silent> <F8> :TagbarToggle<CR>

