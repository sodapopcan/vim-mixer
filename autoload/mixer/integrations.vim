vim9script

export def Define()
  CloseTags()
enddef

def CloseTags()
  if exists('g:closetag_regions') && !has_key(g:closetag_regions, 'elixir')
    g:closetag_regions->extend({'elixir': 'elixirHeexSigil'})
  endif
enddef
