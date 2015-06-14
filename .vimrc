set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'ntpeters/vim-better-whitespace'
Plugin 'tomtom/tcomment_vim'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'marijnh/tern_for_vim'
Plugin 'vim-scripts/AutoComplPop'
Plugin 'OmniSharp/omnisharp-vim'
Plugin 'tpope/vim-dispatch'
Plugin 'kien/ctrlp.vim'
Plugin 'scrooloose/syntastic'
Plugin 'Valloric/YouCompleteMe'
Plugin 'xolox/vim-misc'
Plugin 'flazz/vim-colorschemes'
Plugin 'bling/vim-airline'
Plugin 'airblade/vim-gitgutter'
Plugin 'tpope/vim-fugitive'
Plugin 'scrooloose/nerdtree'

call vundle#end()            " required
filetype plugin indent on    " required
syntax on

" Completion
let g:ycm_filetype_blacklist = { 'html': 1, 'javascript': 1 }
let g:ycm_global_ycm_extra_conf = '~/.ycm_extra_conf.py'
set completeopt-=preview
set completeopt+=longest,menuone
let g:ycm_add_preview_to_completeopt = 0

" OmniSharp
let g:OmniSharp_start_without_solution = 1
let g:syntastic_cs_checkers = ['syntax', 'semantic', 'issues']
let g:OmniSharp_selector_ui = 'unite'
let g:OmniSharp_selector_ui = 'ctrlp'

" Quickfix
nnoremap <silent> <leader>e :cn<CR>
nnoremap <silent> <leader>E :cp<CR>

" Colors
set t_Co=256
colorscheme gruvbox
set background=dark
set cursorline
hi CursorLine guibg=Grey40
set hlsearch
" Removes highlighting from the previous search with the space bar
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>

" Searches for the current word using enter
let g:highlighting = 0
function! Highlighting()
  if g:highlighting == 1 && @/ =~ '^\\<'.expand('<cword>').'\\>$'
    let g:highlighting = 0
    return ":silent nohlsearch\<CR>"
  endif
  let @/ = '\<'.expand('<cword>').'\>'
  let g:highlighting = 1
  return ":silent set hlsearch\<CR>"
endfunction
nnoremap <silent> <expr> <CR> Highlighting()

"
set backspace=2

" Indentation
set tabstop=2
set shiftwidth=2
set expandtab
set number
com! FormatJSON %!python -m json.tool

" Status bar
let g:airline#extensions#tabline#enabled = 1
set laststatus=2
let g:airline_theme='bubblegum'
let g:airline_powerline_fonts = 1

" Explorer sidebar
let g:netrw_liststyle = 3
autocmd vimenter * NERDTree

" Buffers
set hidden
nnoremap <silent> <Tab> :bnext<CR>
nnoremap <silent> <S-Tab> :bprevious<CR>
nnoremap <silent> <leader>q :bp<cr>:bd #<cr>
nnoremap <silent> <leader>Q :bp<cr>:bd! #<cr>

" Windows
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
set splitbelow
set splitright

" Encoding
if has("multi_byte")
  if &termencoding == ""
    let &termencoding = &encoding
  endif
  set encoding=utf-8
  setglobal fileencoding=utf-8
endif

