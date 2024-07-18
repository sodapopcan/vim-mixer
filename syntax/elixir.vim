syn region elixirLambda start="\<fn\>" end="\<end\>" contains=elixirAnonymousFunction keepend
syn region elixirMap matchgroup=elixirMapDelimiter start="%{" end="}" contains=ALLBUT,@elixirNotTop fold
syn region elixirExStruct matchgroup=elixirExDelimiters start="%\%(\w\|\.\)\+"hs=s+1 end="}"he=e-1 contains=ALLBUT,@elixirNotTop fold
hi link elixirExDelimiters Type
syn clear elixirArguments
