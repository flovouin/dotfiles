setlocal shiftwidth=4
setlocal tabstop=4

nnoremap <silent> <C-B> :wa!<CR>:OmniSharpBuildAsync<CR>
nnoremap <silent> <leader>d :OmniSharpGotoDefinition<CR>
nnoremap <silent> <leader>t :OmniSharpFindType<CR>
nnoremap <silent> <leader>s :OmniSharpFindSymbol<CR>
