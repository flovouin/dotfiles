""" Everything related to coding in VIM

"" Completion
" Disable completion for html and javascript as it messes up
" other plugins.
let g:ycm_filetype_blacklist = { 'html': 1, 'javascript': 1 }
let g:ycm_global_ycm_extra_conf = '~/.ycm_extra_conf.py'
set completeopt-=preview
set completeopt+=longest,menuone
let g:ycm_add_preview_to_completeopt = 0

"" Snippets
" Insert snippets without using TAB, already taken by YCM
let g:UltiSnipsExpandTrigger="<C-b>"
let g:UltiSnipsJumpForwardTrigger="<C-b>"
let g:UltiSnipsJumpBackwardTrigger="<C-v>"

"" OmniSharp
let g:OmniSharp_start_without_solution = 0
let g:syntastic_cs_checkers = ['syntax', 'semantic', 'issues']
let g:OmniSharp_selector_ui = 'ctrlp'

"" Quickfix
nnoremap <silent> <Leader>g :cn<CR>
nnoremap <silent> <Leader>G :cp<CR>
