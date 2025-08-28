" This should likely be fixed in elixir.vim
syn region elixirStruct matchgroup=elixirStructDelimiters start="%\u\%(\w\|\.\)\+"hs=s+1 end="}"he=e-1 transparent
hi link elixirStructDelimiters Type

if get(g:, 'mixer_syntax_highlighting', 1)
  if search('^\s*defmodule\s\+.\{-}Router\s\+do')
    syn match elixirPhoenixRouter '\(^\s*\)\@<=\<\(scope\|live\|included\|pipe_through\|live_session\|plug\|pipeline\|post\|get\|put\|delete\|forward\|\options\|head\|match\)\>'
    hi link elixirPhoenixRouter Keyword
  endif
endif
