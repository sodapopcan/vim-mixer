if exists('g:loaded_phx') || &cp
  finish
endif
let g:loaded_phx = 1

function! s:command_exists(cmd)
  return exists(":".a:cmd) == 2
endfunction

function! elixir_ext#define_commands() abort
  if !s:command_exists("R")
    command! -buffer -nargs=0 R call elixir_ext#phx#related()
  endif

  if !s:command_exists("ToPipe")
    command! -buffer -nargs=0 ToPipe call elixir_ext#pipe#to_pipe()
  endif

  if !s:command_exists("FromPipe")
    command! -buffer -nargs=0 FromPipe call elixir_ext#pipe#from_pipe()
  endif
endfunction
