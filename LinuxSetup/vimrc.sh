if v:progname =~? "evim"
  finish
endif

" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set autoindent		" always set autoindenting on
set history=200
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set incsearch		" do incremental searching

" For Win32 GUI: remove 't' flag from 'guioptions': no tearoff menu entries
" let &guioptions = substitute(&guioptions, "t", "", "g")

" Don't use Ex mode, use Q for formatting
map Q gq

" This is an alternative that also works in block mode, but the deleted
" text is lost and it only works for putting the current register.
"vnoremap p "_dp

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

  "autocmd BufEnter *.html setlocal indentexpr=
  "autocmd BufEnter *.css  setlocal indentexpr=
  au BufNewFile,BufRead [Dd]ockerfile,Dockerfile* set filetype=dockerfile
endif " has("autocmd")

set nocindent
set noai
set noautoindent
set nosmartindent
set expandtab
set tabstop=2
set shiftwidth=2
set number
set background=dark " so that vim colors are readable against the default black background
set showcmd         " shows your vim commands as you type
set incsearch       " incremental search
set ignorecase      " ignores case when searching
set smartcase       " respects case if search string contains uppercase chars
set hlsearch        " highlights search results
" set hl+=l:Visual
set wildmode=longest,list
set t_Co=256

if has("pathogen")
  execute pathogen#infect()
endif

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

function JsonPPFunc()
  :%!python -m json.tool
  execute "normal gg=G"
endfunction

function SetFont(n)
  "execute ':set guifont=Inconsolata\ Medium\ ' . a:n
  execute ':set guifont=Osaka-Mono:h' . a:n
endfunction

command Jsonpp call JsonPPFunc()
command RegularFont call SetFont(14)
command BigFont call SetFont(16)
command BiggerFont call SetFont(18)
command BiggestFont call SetFont(24)
command BiggerestFont call SetFont(24)
set synmaxcol=320 "Vim won't crash long lines because we stop syntax

nnoremap <C-W><C-E> <C-W><C-K>

call plug#begin()
Plug 'sheerun/vim-polyglot'
Plug 'arcticicestudio/nord-vim'
Plug 'NLKNguyen/papercolor-theme'
call plug#end()
