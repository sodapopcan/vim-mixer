" mixer.vim - Extra goodies for working with Elixir
" Maintainer:   Andrew Haust <https://andrew.hau.st>
" Version:      0.1

if exists('g:loaded_mixer') || &cp
  finish
endif
let g:loaded_mixer = 1

let g:async_runners = [
      \   'Dispatch',
      \   'Neomake',
      \   'AsyncRunner',
      \   'AsyncDo'
      \ ]

augroup mixer
  autocmd!
  autocmd BufNewFile,BufReadPost * call mixer#setup_buff()
  autocmd FileType elixir,eelixir call mixer#define_mappings()
augroup END

" Options {{{1

let g:mixer_enable_textobj_arg = get(g:, 'mixer_enable_textobj_arg', 1)
let g:mixer_async_command = get(g:, 'mixer_async_command', 0)
