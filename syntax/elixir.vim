" Text objects lean heavily on syntax groups.
" In order to not have to depend on elixir.vim, we need to define our own for
" the groups that matter.  Most of these are copied from elixir.vim
" (https://github.com/elixir-editors/vim-elixir).

" Unavailable in elixir.vim
" syn region elixirLambda start="\<fn\>" end="\<end\>" keepend transparent
" syn region elixirMap matchgroup=elixirMapDelimiter start="%{" end="}" transparent
syn region elixirStruct matchgroup=elixirStructDelimiters start="%\%(\w\|\.\)\+"hs=s+1 end="}"he=e-1 transparent
hi link elixirStructDelimiters Type

if !hlexists('elixirSigil')
  syn match elixirDelimEscape "\\[(<{\[)>}\]/\"'|]" transparent display contained contains=NONE

  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\u\+\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1" contains=elixirDelimEscape transparent
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\u\+{"                end="}"   skip="\\\\\|\\}"   contains=elixirDelimEscape transparent
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\u\+<"                end=">"   skip="\\\\\|\\>"   contains=elixirDelimEscape transparent
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\u\+\["               end="\]"  skip="\\\\\|\\\]"  contains=elixirDelimEscape transparent
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\u\+("                end=")"   skip="\\\\\|\\)"   contains=elixirDelimEscape transparent

  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\l\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1"                                            transparent
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\l{"                end="}"   skip="\\\\\|\\}"   contains=elixirRegexEscapePunctuation transparent
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\l<"                end=">"   skip="\\\\\|\\>"   contains=elixirRegexEscapePunctuation transparent
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\l\["               end="\]"  skip="\\\\\|\\\]"  contains=elixirRegexEscapePunctuation transparent
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\l("                end=")"   skip="\\\\\|\\)"   contains=elixirRegexEscapePunctuation transparent
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\l\/"               end="\/"  skip="\\\\\|\\\/"  contains=elixirRegexEscapePunctuation transparent

  " Sigils surrounded with heredoc
  syn region elixirSigil matchgroup=elixirSigilDelimiter start=+\~\a\z("""\)+ end=+^\s*\z1+ skip=+\\"+  transparent
  syn region elixirSigil matchgroup=elixirSigilDelimiter start=+\~\a\z('''\)+ end=+^\s*\z1+ skip=+\\'+  transparent
endif

if !hlexists('elixirRegexEscapePunctuation')
  syn match elixirRegexEscapePunctuation "?\|\\.\|*\|\\\[\|\\\]\|+\|\\^\|\\\$\|\\|\|\\(\|\\)\|\\{\|\\}" contained transparent
endif

if !hlexists('elixirAtom')
  syn match elixirAtom '\(:\)\@<!:\%([a-zA-Z_*]\w*\%([?!]\|=[>=]\@!\)\?\|<>\|===\?\|>=\?\|<=\?\)' contains=elixirAtom transparent
  syn match elixirAtom '\(:\)\@<!:\%(<=>\|&&\?\|%\(()\|\[\]\|{}\)\|++\?\|--\?\|||\?\|!\|//\|[%&`/|]\)' contains=elixirAtom transparent
  syn match elixirAtom "\%([a-zA-Z_]\w*[?!]\?\):\(:\)\@!" transparent
endif

if !hlexists('elixirComment')
  syn match elixirComment '#.*' transparent
endif

if !hlexists('elixirDocString')
  syn region elixirDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1"  transparent
  syn region elixirDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]{"                end="}"   skip="\\\\\|\\}"    transparent
  syn region elixirDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]<"                end=">"   skip="\\\\\|\\>"    transparent
  syn region elixirDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\["               end="\]"  skip="\\\\\|\\\]"   transparent
  syn region elixirDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]("                end=")"   skip="\\\\\|\\)"    transparent
  syn region elixirDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\z("\)+                 end=+\z1+ skip=+\\\\\|\\\z1+  transparent
  syn region elixirDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\z("""\)+               end=+^\s*\z1+                 transparent
  syn region elixirDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\z('''\)+         end=+^\s*\z1+                 transparent
  syn region elixirDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\z("""\)+         end=+^\s*\z1+                 transparent
endif

if !hlexists('elixirVariable')
  syn match elixirVariable '@[a-z]\w*'
  syn match elixirVariable '&\d\+'
endif
