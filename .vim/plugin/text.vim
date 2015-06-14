""" Everything related to generic text editing in VIM

"" File settings
" Reload files edited outside of VIM
set autoread

"" Indentation
set tabstop=2
set shiftwidth=2
set expandtab
com! FormatJSON %!python -m json.tool

"" Encoding
if has("multi_byte")
  if &termencoding == ""
    let &termencoding = &encoding
  endif
  set encoding=utf-8
  setglobal fileencoding=utf-8
endif

"" Search
" Find the next match as we type the search
set incsearch
" Highlight searches by default
set hlsearch
" Ignore case when searching...
set ignorecase
" ...unless we type a capital
set smartcase
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
