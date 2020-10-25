" MAPPINGS
let mapleader = ' '

nmap <silent> <leader>w :w<CR>
nmap <silent> <leader>q :bdelete<CR>

" Refresh neovim configs from everywhere
if g:is_win
	nmap <leader>sou :source ~/AppData/Local/nvim/init.vim <CR>
else 
	nmap <leader>sou :source ~/.config/nvim/init.vim <CR>

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
nmap <leader>n :noh <CR>

" Move between split terminals
nmap <silent> <A-k> :wincmd k<CR>
nmap <silent> <A-j> :wincmd j<CR>
nmap <silent> <A-h> :wincmd h<CR>
nmap <silent> <A-l> :wincmd l<CR>

" arrow keys resize windows
nnoremap <silent> <Leader><Left> :vertical resize -10<CR>
nnoremap <silent> <Leader><Right> :vertical resize +10<CR>
nnoremap <silent> <Leader><Up> :resize -10<CR>
nnoremap <silent> <Leader><Down> :resize +10<CR>

" Move between buffers
map <silent> <Tab> :bnext<CR>
map <silent> <S-Tab> :bprevious<CR>

