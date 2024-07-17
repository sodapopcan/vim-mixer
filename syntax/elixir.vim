" syn match elixirStructName '%\%([A-Z][a-zA-Z.]\+\)\?{' contains=elixirAlias
" syn region elixirStructBody start="%\%([A-Z][a-zA-Z.]\+\)\?{" end="}" contains=elixirMap
" This cluster is copied from elixir.vim
syn region elixirExStruct  matchgroup=NONE start="%[A-Z]\%([A-Za-z.]\+\)\?{" end="}" contains=ALLBUT,@elixirNotTop fold
syn region elixirLambda start="\<fn\>" end="\<end\>" contains=elixirAnonymousFunction keepend
  " let open_regex = '%\%([A-Z][a-zA-Z.]\+\)\?{'
