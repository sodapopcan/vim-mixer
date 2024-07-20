" Text objects lean heavily on syntax groups.
" In order to not have to depend on elixir.vim, we need to define our own for
" the groups that matter.  Most of these are copied from elixir.vim
" (https://github.com/elixir-editors/vim-elixir).

" Unavailable in elixir.vim
syn region elixirMixLambda start="\<fn\>" end="\<end\>" keepend transparent
" syn region elixirMixMap matchgroup=elixirMapDelimiter start="%{" end="}" transparent
syn region elixirMixStruct matchgroup=elixirMixStructDelimiters start="%\%(\w\|\.\)\+"hs=s+1 end="}"he=e-1 transparent
hi link elixirMixStructDelimiters Type
syn region elixirArguments start="(" end=")" contained contains=elixirMixStruct,elixirMap transparent
" syn region elixirMixTuple matchgroup=NONE start="\(\w\|#\)\@<!{" end="}" transparent

if !hlexists('elixirSigil')
  syn region elixirMixSigil matchgroup=elixirSigilDelimiter start="\~\u\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1" contains=elixirDelimEscape transparent
  syn region elixirMixSigil matchgroup=elixirSigilDelimiter start="\~\u{"                end="}"   skip="\\\\\|\\}"   contains=elixirDelimEscape transparent
  syn region elixirMixSigil matchgroup=elixirSigilDelimiter start="\~\u<"                end=">"   skip="\\\\\|\\>"   contains=elixirDelimEscape transparent
  syn region elixirMixSigil matchgroup=elixirSigilDelimiter start="\~\u\["               end="\]"  skip="\\\\\|\\\]"  contains=elixirDelimEscape transparent
  syn region elixirMixSigil matchgroup=elixirSigilDelimiter start="\~\u("                end=")"   skip="\\\\\|\\)"   contains=elixirDelimEscape transparent

  syn region elixirMixSigil matchgroup=elixirSigilDelimiter start="\~\l\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1"                                                              transparent
  syn region elixirMixSigil matchgroup=elixirSigilDelimiter start="\~\l{"                end="}"   skip="\\\\\|\\}"   contains=@elixirStringContained,elixirRegexEscapePunctuation transparent
  syn region elixirMixSigil matchgroup=elixirSigilDelimiter start="\~\l<"                end=">"   skip="\\\\\|\\>"   contains=@elixirStringContained,elixirRegexEscapePunctuation transparent
  syn region elixirMixSigil matchgroup=elixirSigilDelimiter start="\~\l\["               end="\]"  skip="\\\\\|\\\]"  contains=@elixirStringContained,elixirRegexEscapePunctuation transparent
  syn region elixirMixSigil matchgroup=elixirSigilDelimiter start="\~\l("                end=")"   skip="\\\\\|\\)"   contains=@elixirStringContained,elixirRegexEscapePunctuation transparent
  syn region elixirMixSigil matchgroup=elixirSigilDelimiter start="\~\l\/"               end="\/"  skip="\\\\\|\\\/"  contains=@elixirStringContained,elixirRegexEscapePunctuation transparent

  " Sigils surrounded with heredoc
  syn region elixirMixSigil matchgroup=NONE start=+\~\a\z("""\)+ end=+^\s*\z1+ skip=+\\"+  transparent
  syn region elixirMixSigil matchgroup=NONE start=+\~\a\z('''\)+ end=+^\s*\z1+ skip=+\\'+  transparent
endif

syn region elixirMixMap matchgroup=NONE start="%{" end="}" keepend transparent

if !hlexists('elixirAtom')
  syn match elixirMixAtom '\(:\)\@<!:\%([a-zA-Z_*]\w*\%([?!]\|=[>=]\@!\)\?\|<>\|===\?\|>=\?\|<=\?\)' contains=elixirAtom transparent
  syn match elixirMixAtom '\(:\)\@<!:\%(<=>\|&&\?\|%\(()\|\[\]\|{}\)\|++\?\|--\?\|||\?\|!\|//\|[%&`/|]\)' contains=elixirAtom transparent
  syn match elixirMixAtom "\%([a-zA-Z_]\w*[?!]\?\):\(:\)\@!" transparent
endif

if !hlexists('elixirComment')
  syn match elixirMixComment '#.*' transparent
endif

if !hlexists('elixirDocString')
  syn region elixirMixDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1"  transparent
  syn region elixirMixDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]{"                end="}"   skip="\\\\\|\\}"    transparent
  syn region elixirMixDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]<"                end=">"   skip="\\\\\|\\>"    transparent
  syn region elixirMixDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\["               end="\]"  skip="\\\\\|\\\]"   transparent
  syn region elixirMixDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]("                end=")"   skip="\\\\\|\\)"    transparent
  syn region elixirMixDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\z("\)+                 end=+\z1+ skip=+\\\\\|\\\z1+  transparent
  syn region elixirMixDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\z("""\)+               end=+^\s*\z1+                 transparent
  syn region elixirMixDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\z('''\)+         end=+^\s*\z1+                 transparent
  syn region elixirMixDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\z("""\)+         end=+^\s*\z1+                 transparent
endif

if !hlexists('elixirVariable')
  syn match elixirMixVariable '@[a-z]\w*'
  syn match elixirMixVariable '&\d\+'
endif
