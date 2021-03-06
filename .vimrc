set nocompatible              " be iMproved, required
filetype off                  " required

let mapleader = ","

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'ntpeters/vim-better-whitespace'
Plugin 'tomtom/tcomment_vim'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'marijnh/tern_for_vim'
Plugin 'vim-scripts/AutoComplPop'
Plugin 'tpope/vim-dispatch'
Plugin 'kien/ctrlp.vim'
Plugin 'scrooloose/syntastic'
Plugin 'xolox/vim-misc'
Plugin 'flazz/vim-colorschemes'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'airblade/vim-gitgutter'
Plugin 'tpope/vim-fugitive'
Plugin 'scrooloose/nerdtree'
Plugin 'honza/vim-snippets'
Plugin 'sirver/ultisnips'
Plugin 'mileszs/ack.vim'
Plugin 'keith/swift.vim'
Plugin 'keith/sourcekittendaemon.vim'
Plugin 'tpope/vim-surround'
Plugin 'raimondi/delimitmate'
Plugin 'tokorom/syntastic-swiftlint.vim'
Plugin 'rizzatti/dash.vim'
Plugin 'pangloss/vim-javascript'

call vundle#end()            " required
filetype plugin indent on    " required
syntax on
