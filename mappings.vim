" MAPPINGS
let mapleader = ' '

nmap <silent> <leader>w :w<CR>
nmap <silent> <leader>q :bdelete<CR>

" Refresh neovim configs from everywhere
if g:is_win
	nmap <leader>sou :source ~/AppData/Local/nvim/init.vim<CR>
else 
  nmap <leader>sou :source ~/.config/nvim/init.vim<CR>
endif

" Copy text to system clipboard
vnoremap y "+y
nnoremap y "+y

" Paste text from system clipboard
vnoremap p "+p
nnoremap p "+p
vnoremap P "+P
nnoremap P "+P

" Cut text to system clipboard
vnoremap d "+d
nnoremap d "+d

" Go to start or end of line easier
nnoremap H ^
xnoremap H ^
nnoremap L g_
xnoremap L g_

" Clean search
nmap <silent> <leader>n :noh <CR>

" Move between split terminals
nmap <silent> <Leader>k :wincmd k<CR>
nmap <silent> <Leader>j :wincmd j<CR>
nmap <silent> <Leader>h :wincmd h<CR>
nmap <silent> <Leader>l :wincmd l<CR>

" arrow keys resize windows
nnoremap <silent> <Leader><Left> :vertical resize -10<CR>
nnoremap <silent> <Leader><Right> :vertical resize +10<CR>
nnoremap <silent> <Leader><Up> :resize -10<CR>
nnoremap <silent> <Leader><Down> :resize +10<CR>

" Move between buffers
map <silent> <Tab> :bnext<CR>
map <silent> <S-Tab> :bprevious<CR>

" Manipulate insert line
nnoremap <leader>o o<Esc>
nnoremap <leader>O O<Esc>

" Map scroll
map <silent> <C-UP> <C-Y>
map <silent> <C-Down> <C-E>

" Move between words
imap <C-l> <C-Right>
imap <C-h> <C-Left>

" Select all file
nmap <C-a> ^ggvG<S-l>

" Integrated Terminal
function! OpenTerminal()
  split term://zsh
endfunction

nnoremap <c-t> :call OpenTerminal()<CR>

" move lines
nnoremap <A-Down> :m .+1<CR>==    
vnoremap <A-Up> :m '<-2<CR>gv=gv
vnoremap <A-Down> :m '>+1<CR>gv=gv    
nnoremap <A-Up> :m .-2<CR>==      

