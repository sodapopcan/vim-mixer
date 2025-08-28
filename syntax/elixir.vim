" This should likely be fixed in elixir.vim
syn region elixirStruct matchgroup=elixirStructDelimiters start="%\u\%(\w\|\.\)\+"hs=s+1 end="}"he=e-1 transparent
hi link elixirStructDelimiters Type

syn match elixirPackageDefs "\%(deflua\|defprop\)"
hi link elixirPackageDefs Define

if get(g:, 'mixer_syntax_highlighting', 1)
  if search('^\s*defmodule\s\+.\{-}Router\s\+do')
    syn match elixirPhoenixRouter '^\s*\<\(scope\|live\|included\|pipe_through\|live_session\|plug\|pipeline\|post\|get\|put\|delete\|forward\|\options\|head\|match\)\>'
    hi link elixirPhoenixRouter Keyword
  endif

  if expand('%:p:h') =~ '\/config$'
    syn match elixirConfig '^\s*\<config\>:\@!'
    hi link elixirConfig Keyword

    syn match elixirImportConfig '^\s*\<import_config\>:\@!'
    hi link elixirImportConfig Include
  endif
endif
