" This should likely be fixed in elixir.vim
syn region elixirStruct matchgroup=elixirStructDelimiters start="%\u\%(\w\|\.\)\+"hs=s+1 end="}"he=e-1 transparent
hi link elixirStructDelimiters Type

syn match elixirPackageDefs "\%(deflua\|defprop\)"
hi link elixirPackageDefs Define

if get(g:, 'mixer_syntax_highlighting', 1)
  if search('^\s*use ExUnit.CaseTemplate')
    syn match elixirCaseTemplate '\<using\>'
    hi link elixirCaseTemplate Keyword
  endif

  if search('^\s*defmodule\s\+.\{-}Router\s\+do')
    syn match elixirPhoenixRouter '^\s*\<\%(scope\|live\|included\|pipe_through\|live_session\|plug\|pipeline\|post\|get\|put\|delete\|forward\|\options\|head\|match\)\>:\@!'
    hi link elixirPhoenixRouter Keyword
  endif

  if search('^\s*use\s.*Schema')
    syn match elixirEctoSchema '^\s*\<\%(\%[embedded_]schema\|field\|belongs_to\|has_many\|has_one\|many_to_many\|embeds_one\|embeds_many\)\>:\@!'
    hi link elixirEctoSchema Keyword
  endif

  if search('^\s*use\s.*Migration')
    syn match elixirMigration '^\s*\<\%(create\%[_if_not_exists]\=\|alter\|add\%[_if_not_exists]\|drop\%[_if_exists]\|remove\%[_if_exists]\|modify\|execute\%[_file]\)\>:\@!'
    hi link elixirMigration Keyword
  endif

  if expand('%:p:h') =~ '\/config$'
    syn match elixirConfig '^\s*\<config\>:\@!'
    hi link elixirConfig Keyword

    syn match elixirImportConfig '^\s*\<import_config\>:\@!'
    hi link elixirImportConfig Include
  endif
endif
