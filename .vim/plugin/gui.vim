""" Everything related to the appearance of VIM

"" Colors
set t_Co=256
" We silence the colour scheme change because it might not work if
" the plugins have not been downloaded yet.
silent! colorscheme gruvbox
set background=dark
set cursorline
hi CursorLine guibg=Grey40
set lazyredraw
set ttyfast

"" Scrolling and moving around
" Line numbers
set number
" Start scrolling when we're 8 lines away from margins
set scrolloff=8
set sidescrolloff=15
set sidescroll=1
" Set the backspace key like we like it
set backspace=2

"" Status bar
" Always show the buffer tab bar
let g:airline#extensions#tabline#enabled = 1
" Always show the status bar
set laststatus=2
let g:airline_theme='bubblegum'
let g:airline_powerline_fonts = 1

"" Explorer sidebar
let g:netrw_liststyle = 3
autocmd vimenter * NERDTree
autocmd vimenter * wincmd p
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

"" Buffers
" Alows switching between buffers without saving them first
set hidden
" This closes a buffer and goes to the previous one.
" If there is only one buffer left, it creates an empty one.
function! DeleteBuffer(save_first, force)
  let s:result = ""
  if a:save_first == 1
    let s:result = s:result.":w\<CR>"
  endif
  " Only one buffer left open
  if len(filter(range(1, bufnr('$')), 'buflisted(v:val)')) == 1
    let s:result = s:result.":enew\<CR>:bn\<CR>"
  else
    let s:result = s:result.""
  endif

  let s:result = s:result.":bp\<CR>:bd"
  if a:force == 1
    let s:result = s:result."!"
  endif
  let s:result = s:result." #\<CR>"

  return s:result
endfunction
nnoremap <silent> <expr> <Leader>q DeleteBuffer(0, 0)
nnoremap <silent> <expr> <Leader>Q DeleteBuffer(0, 1)
nnoremap <silent> <expr> <Leader>wq DeleteBuffer(1, 0)

" Navigation between buffers
nnoremap <silent> <Tab> :bnext<CR>
nnoremap <silent> <S-Tab> :bprevious<CR>

"" Windows
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
set splitbelow
set splitright
