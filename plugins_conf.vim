" ---------------
" PLUGINS OPTIONS
" ---------------

" THEME SELECTION 
silent! colorscheme gruvbox

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
let NERDTreeShowLineNumbers = 1

" fzf options
" set wildmode=list:longest,list:full
set wildignore+=*.o,*.obj,.git,*.rbc,*.pyc,__pycache__,node_modules,vendor,coverage

if !g:is_win
	let $FZF_DEFAULT_COMMAND =  "find * -path '*/\.*/*' -prune -o -path 'null/**' -prune -o -path 'vendor/**' -prune -o -path 'coverage/**' -prune -o -path 'node_modules/**' -prune -o -path 'target/**' -prune -o -path 'dist/**' -prune -o  -type f -print -o -type l -print 2> /dev/null"

endif

" vim lightline options
let g:lightline = {
  \ 'colorscheme': 'material',
  \ 'active': {
  \   'left': [ ['mode', 'paste'], ['readonly', 'filename', 'gitbranch'] ],
  \   'right': [ ['lineinfo'], ['percent'], ['fileformat', 'fileencoding', 'filetype'] ]
  \ },
  \ 'separator': {
  \   'right': '',
  \   'left': '',
  \ },
  \ 'subseparator': {
  \   'right': '',
  \   'left': '',
  \ },
  \ 'component_function': {
  \   'gitbranch': 'LightlineGitbranch',
  \   'lineinfo': 'LightlineLineinfo',
  \ },
  \ 'component_raw': {
  \   'buffers': 1
  \ }
  \ }
lua << EOF
require("bufferline").setup {
    options = {
      numbers = "ordinal",
      close_command = "bdelete! %d",
      right_mouse_command = "bdelete! %d", 
      left_mouse_command = "buffer %d",
      middle_mouse_command = nil,
      indicator_icon = "▎",
      buffer_close_icon = "",
      modified_icon = "●",
      close_icon = "",
      left_trunc_marker = "",
      right_trunc_marker = "",
      name_formatter = function(buf) -- buf contains a "name", "path" and "bufnr"
        if buf.name:match("%.md") then
          return vim.fn.fnamemodify(buf.name, ":t:r")
        end
      end,
      max_name_length = 18,
      max_prefix_length = 15, 
      tab_size = 18,
      diagnostics = "coc",
      diagnostics_update_in_insert = false,
      diagnostics_indicator = function(count, level, diagnostics_dict, context)
        local icon = level:match("error") and " " or " "
        return " " .. icon .. count
      end,
      offsets = {{filetype = "NvimTree", text = "File Explorer", text_align = "left"}},
      show_buffer_icons = true,
      show_buffer_close_icons = true,
      show_close_icon = true,
      show_tab_indicators = true,
      persist_buffer_sort = true, 
      separator_style = "slant",
      enforce_regular_tabs = false,
      always_show_bufferline = true,
      sort_by = "id"
  }
}

EOF

function! LightlineGitbranch() abort
    if exists('*fugitive#head')
        let branch = fugitive#head()
        return branch !=# '' ? branch[0:35] . ' ' : ''
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
  \ 'coc-eslint'
\]

" coc-python options
let g:python_recommended_style = 0 

" vim-javascript options
let g:javascript_plugin_jsdoc = 1

" indentLine options
let g:indentLine_char_list = ['|', '¦', '┆', '┊']
autocmd FileType json IndentLinesDisable



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

" bufferline mappings
nnoremap <silent> fj :BufferLinePick<CR>
nnoremap <silent> fk :BufferLinePickClose<CR>

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

" JSDoc mappings
nmap <silent> <C-l> <Plug>(jsdoc)
