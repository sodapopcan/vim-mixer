" This should likely be fixed in elixir.vim
syn region elixirStruct matchgroup=elixirStructDelimiters start="%\%(\w\|\.\)\+"hs=s+1 end="}"he=e-1 transparent
hi link elixirStructDelimiters Type
