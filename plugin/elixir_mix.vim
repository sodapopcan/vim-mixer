" elixir-mix.vim - Extra goodies for working with Elixir
" Maintainer:   Andrew Haust <https://andrew.hau.st>
" Version:      0.1

if exists('g:loaded_elixir_mix') || &cp
  finish
endif
let g:loaded_elixir_mix = 1

let g:elixir_mix_define_projections = get(g:, "elixir_mix_define_projections", 1)
