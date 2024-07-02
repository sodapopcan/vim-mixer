" This should likely be fixed in elixir.vim
syn region elixirStruct matchgroup=elixirStructDelimiters start="%\%(\w\|\.\)\+"hs=s+1 end="}"he=e-1 transparent
hi link elixirStructDelimiters Type

if get(g:, 'mixer_syntax_highlighting', 1)
  syn match elixirPhoenix "\C\(^\s*\)\@<=\<\(scope\|live\|on_mount\|included\|pipe_through\|live_session\|plug\|pipeline\|post\|get\|put\|delete\|forward\|\options\|head\|match\|assert_\%(\k\+\)\=\)\>"
  hi link elixirPhoenix Include
endif
