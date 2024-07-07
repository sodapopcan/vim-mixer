if exists('g:loaded_phx') || &cp
  finish
endif
let g:loaded_phx = 1

let g:elixir_ext_define_projections = get(g:, "elixir_ext_define_projections", 1)
