" ---------------
" PLUGINS OPTIONS
" ---------------

" THEME SELECTION 
silent! colorscheme onedark

" Material theme options
if g:colors_name is 'material'
  let g:material_theme_style = 'darker-community'
  let g:material_terminal_italics = 1
endif

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
let g:NERDTreeWinSize = 35

" fzf options
" set wildmode=list:longest,list:full
set wildignore+=*.o,*.obj,.git,*.rbc,*.pyc,__pycache__,node_modules,vendor,coverage

if !g:is_win
	let $FZF_DEFAULT_COMMAND =  "find * -path '*/\.*' -prune -o -path 'vendor/**' -prune -o -path 'coverage/**' -prune -o -path 'node_modules/**' -prune -o -path 'target/**' -prune -o -path 'dist/**' -prune -o  -type f -print -o -type l -print 2> /dev/null"

endif

" vim lightline options
let g:lightline = {
  \ 'colorscheme': 'one',
  \ 'active': {
  \   'left': [ ['mode', 'paste'], ['readonly', 'filename', 'gitbranch'] ],
  \   'right': [ ['lineinfo'], ['percent'], ['fileformat', 'fileencoding', 'filetype'] ]
  \ },
  \ 'tabline': {
  \   'left': [ ['buffers'] ],
  \   'right': [ ['close'] ]
  \ },
  \ 'separator': {
  \   'right': '',
  \   'left': '',
  \ },
  \ 'subseparator': {
  \   'right': '',
  \   'left': '',
  \ },
  \ 'tabline_separator': {
  \   'right': '',
  \   'left': '',
  \ },
  \ 'tabline_subseparator': {
  \   'right': '',
  \   'left': '',
  \ },
  \ 'component': {
  \ },
  \ 'component_expand': {
  \   'buffers': 'lightline#bufferline#buffers'
  \ },
  \ 'component_type': {
  \   'buffers': 'tabsel'
  \ },
  \ 'component_function': {
  \   'gitbranch': 'LightlineGitbranch',
  \   'lineinfo': 'LightlineLineinfo',
  \ }
  \ }

let g:lightline#bufferline#filename_modifier = ':t:r'
let g:lightline#bufferline#show_number  = 2
let g:lightline#bufferline#unnamed = 'No Name'
let g:lightline#bufferline#enable_devicons = 1
let g:lightline#bufferline#unicode_symbols = 1

function! LightlineGitbranch() abort
    if exists('*fugitive#head')
        let branch = fugitive#head()
        return branch !=# '' ? branch . ' ' : ''
   endif
    return fugitive#head()
endfunction

function! LightlineLineinfo()
  return col('.') . ':' . line('.') . '/' . line('$')
endfunction

" coc plugins autoinstall
" List of coc plugins I use
let g:coc_global_extensions = [
  \ 'coc-pairs',
  \ 'coc-snippets',
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
	\ 'coc-prettier',
  \ 'coc-kotlin',
\]

" coc-python options
let g:python_recommended_style = 0 

" vim-javascript options
let g:javascript_plugin_jsdoc = 1




" ----------------
" PLUGINS MAPPINGS
" ----------------

" NERDTree mappings
map <silent> <leader>m :NERDTreeToggle<CR>
map <silent> <leader>c :NERDTreeFind<CR>

" fzf mappings
nnoremap <silent> <C-p> :FZF -m<CR>
nnoremap <silent> <C-G> :Ag <CR>

" easymotion mappings

" lightline mappings
nmap <Leader>1 <Plug>lightline#bufferline#go(1)
nmap <Leader>2 <Plug>lightline#bufferline#go(2)
nmap <Leader>3 <Plug>lightline#bufferline#go(3)
nmap <Leader>4 <Plug>lightline#bufferline#go(4)
nmap <Leader>5 <Plug>lightline#bufferline#go(5)
nmap <Leader>6 <Plug>lightline#bufferline#go(6)
nmap <Leader>7 <Plug>lightline#bufferline#go(7)
nmap <Leader>8 <Plug>lightline#bufferline#go(8)
nmap <Leader>9 <Plug>lightline#bufferline#go(9)
nmap <Leader>0 <Plug>lightline#bufferline#go(10)

nmap <Leader>d1 <Plug>lightline#bufferline#delete(1)
nmap <Leader>d2 <Plug>lightline#bufferline#delete(2)
nmap <Leader>d3 <Plug>lightline#bufferline#delete(3)
nmap <Leader>d4 <Plug>lightline#bufferline#delete(4)
nmap <Leader>d5 <Plug>lightline#bufferline#delete(5)
nmap <Leader>d6 <Plug>lightline#bufferline#delete(6)
nmap <Leader>d7 <Plug>lightline#bufferline#delete(7)
nmap <Leader>d8 <Plug>lightline#bufferline#delete(8)
nmap <Leader>d9 <Plug>lightline#bufferline#delete(9)
nmap <Leader>d0 <Plug>lightline#bufferline#delete(10)

" coc mappings
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <F2> <Plug>(coc-rename)

nnoremap <silent> K :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Remap <C-f> and <C-b> for scroll float windows/popups.
" Note coc#float#scroll works on neovim >= 0.4.3 or vim >= 8.2.0750
nnoremap <nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
nnoremap <nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
inoremap <nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"

inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
				\: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" tagbar mappings
nmap <silent> <F8> :TagbarToggle<CR>

" GitGutter mappings
nmap <silent> gp :GitGutterPreviewHunk<CR>
