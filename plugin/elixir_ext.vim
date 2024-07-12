" elixir-ext.vim - Extra goodies for working with Elixir
" Maintainer:   Andrew Haust <https://andrew.hau.st>
" Version:      0.1

if exists('g:loaded_elixir_ext') || &cp
  finish
endif
let g:loaded_elixir_ext = 1

let g:elixir_ext_define_projections = get(g:, "elixir_ext_define_projections", 1)
