xnoremap <silent> y y:call system("wl-copy", @")<CR>

set nocompatible
syntax on
filetype plugin indent on
set background=dark
set termguicolors
set number
set relativenumber

" Force vim syntax for vimrc-like files
autocmd BufRead,BufNewFile *.vim,.vimrc,vimrc set filetype=vim

" Base
highlight Normal       guifg=#9cffdf guibg=NONE
highlight NonText      guifg=#5c5470 guibg=NONE
highlight EndOfBuffer  guifg=#3a3448 guibg=NONE
highlight SignColumn   guifg=#8d94aa guibg=NONE

" Line numbers
highlight LineNr       guifg=#6f6880 guibg=NONE
highlight CursorLineNr guifg=#f5a6d6 guibg=NONE gui=bold

" Comments
highlight Comment      guifg=#8d94aa guibg=NONE gui=italic

" Pink: commands / keywords / control flow
highlight Statement    guifg=#f5a6d6 guibg=NONE gui=NONE
highlight Conditional  guifg=#f5a6d6 guibg=NONE gui=NONE
highlight Repeat       guifg=#f5a6d6 guibg=NONE gui=NONE
highlight Keyword      guifg=#f5a6d6 guibg=NONE gui=NONE
highlight Exception    guifg=#f5a6d6 guibg=NONE gui=NONE

" Purple: constants / operators / preprocessor
highlight Constant     guifg=#c792ea guibg=NONE gui=NONE
highlight Boolean      guifg=#c792ea guibg=NONE gui=NONE
highlight Operator     guifg=#c792ea guibg=NONE gui=NONE
highlight PreProc      guifg=#d7a8ff guibg=NONE gui=NONE
highlight Include      guifg=#d7a8ff guibg=NONE gui=NONE
highlight Define       guifg=#d7a8ff guibg=NONE gui=NONE
highlight Macro        guifg=#d7a8ff guibg=NONE gui=NONE

" Mint / aqua: names, functions, strings, types
highlight Identifier   guifg=#9cffdf guibg=NONE gui=NONE
highlight Function     guifg=#89dceb guibg=NONE gui=NONE
highlight String       guifg=#89dceb guibg=NONE gui=NONE
highlight Character    guifg=#89dceb guibg=NONE gui=NONE
highlight Type         guifg=#8ab4f8 guibg=NONE gui=NONE
highlight Structure    guifg=#8ab4f8 guibg=NONE gui=NONE
highlight Typedef      guifg=#8ab4f8 guibg=NONE gui=NONE

" Numbers / errors: pink-red, not harsh red
highlight Number       guifg=#ffc0e4 guibg=NONE gui=NONE
highlight Float        guifg=#ffc0e4 guibg=NONE gui=NONE
highlight Error        guifg=#c98290 guibg=NONE gui=NONE
highlight ErrorMsg     guifg=#c98290 guibg=NONE gui=NONE
highlight WarningMsg   guifg=#f5a6d6 guibg=NONE gui=NONE

" Punctuation / special
highlight Special      guifg=#d7a8ff guibg=NONE gui=NONE
highlight Delimiter    guifg=#cfd7e6 guibg=NONE gui=NONE

" Search / visual
highlight Search       guifg=#f4fff9 guibg=#4b3d66 gui=NONE
highlight IncSearch    guifg=#15111f guibg=#f5a6d6 gui=bold
highlight Visual       guifg=#f4fff9 guibg=#4b3d66

" Vimscript-specific groups
highlight vimCommand   guifg=#f5a6d6 guibg=NONE gui=NONE
highlight vimMap       guifg=#f5a6d6 guibg=NONE gui=NONE
highlight vimMapLhs    guifg=#89dceb guibg=NONE gui=NONE
highlight vimMapRhs    guifg=#9cffdf guibg=NONE gui=NONE
highlight vimOption    guifg=#89dceb guibg=NONE gui=NONE
highlight vimSet       guifg=#f5a6d6 guibg=NONE gui=NONE
highlight vimHiGroup   guifg=#89dceb guibg=NONE gui=NONE
highlight vimHiAttrib  guifg=#d7a8ff guibg=NONE gui=NONE
highlight vimNotation  guifg=#ffc0e4 guibg=NONE gui=NONE
highlight vimMapModKey guifg=#ffc0e4 guibg=NONE gui=NONE
highlight vimFuncName  guifg=#89dceb guibg=NONE gui=NONE
