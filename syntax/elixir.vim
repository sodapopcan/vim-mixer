" syn match elixirStructName '%\%([A-Z][a-zA-Z.]\+\)\?{' contains=elixirAlias
" syn region elixirStructBody start="%\%([A-Z][a-zA-Z.]\+\)\?{" end="}" contains=elixirMap
" This cluster is copied from elixir.vim
syn match elixirExStructDelimiter '%' contained containedin=elixirStruct
syn region elixirExStruct  matchgroup=NONE start="%\%([A-Za-z.]\+\){" end="}" contains=ALLBUT,@elixirNotTop fold
syn region elixirLambda start="\<fn\>" end="\<end\>" contains=elixirAnonymousFunction keepend
