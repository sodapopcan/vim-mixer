" Text objects lean heavily on syntax groups.
" In order to not have to depend on elixir.vim, we need to define our own for
" the groups that matter.  Most of these are copied from elixir.vim
" (https://github.com/elixir-editors/vim-elixir).

" Unavailable in elixir.vim
syn region elixirMixLambda start="\<fn\>" end="\<end\>" keepend transparent
syn region elixirMixMap matchgroup=elixirMapDelimiter start="%{" end="}" transparent
syn region elixirMixStruct matchgroup=elixirMixStructDelimiters start="%\%(\w\|\.\)\+"hs=s+1 end="}"he=e-1 transparent contains=elixirStruct
hi link elixirMixStructDelimiters Type
syn region elixirArguments start="(" end=")" contained contains=elixirMixStruct,elixirMixMap transparent
" syn region elixirMixTuple matchgroup=NONE start="\(\w\|#\)\@<!{" end="}" transparent

" Fix elixir.vim's sigils
" TODO: Remove this when it's fixed in elixir.vim
if hlexists('elixirSigil')
  syn clear elixirSigil elixirSigilDelimiter
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\u\+\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1" contains=elixirDelimEscape fold
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\u\+{"                end="}"   skip="\\\\\|\\}"   contains=elixirDelimEscape fold
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\u\+<"                end=">"   skip="\\\\\|\\>"   contains=elixirDelimEscape fold
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\u\+\["               end="\]"  skip="\\\\\|\\\]"  contains=elixirDelimEscape fold
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\u\+("                end=")"   skip="\\\\\|\\)"   contains=elixirDelimEscape fold

  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\l\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1"                                                              fold
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\l{"                end="}"   skip="\\\\\|\\}"   contains=@elixirStringContained,elixirRegexEscapePunctuation fold
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\l<"                end=">"   skip="\\\\\|\\>"   contains=@elixirStringContained,elixirRegexEscapePunctuation fold
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\l\["               end="\]"  skip="\\\\\|\\\]"  contains=@elixirStringContained,elixirRegexEscapePunctuation fold
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\l("                end=")"   skip="\\\\\|\\)"   contains=@elixirStringContained,elixirRegexEscapePunctuation fold
  syn region elixirSigil matchgroup=elixirSigilDelimiter start="\~\l\/"               end="\/"  skip="\\\\\|\\\/"  contains=@elixirStringContained,elixirRegexEscapePunctuation fold

  " Sigils surrounded with heredoc
  syn region elixirSigil matchgroup=elixirSigilDelimiter start=+\~\a\z("""\)+ end=+^\s*\z1+ skip=+\\"+ fold
  syn region elixirSigil matchgroup=elixirSigilDelimiter start=+\~\a\z('''\)+ end=+^\s*\z1+ skip=+\\'+ fold
endif

if !hlexists('elixirMap')
  syn region elixirMixMap matchgroup=NONE start="%{" end="}" transparent
endif

if !hlexists('elixirAtom')
  syn match elixirMixAtom '\(:\)\@<!:\%([a-zA-Z_*]\w*\%([?!]\|=[>=]\@!\)\?\|<>\|===\?\|>=\?\|<=\?\)' transparent
  syn match elixirMixAtom '\(:\)\@<!:\%(<=>\|&&\?\|%\(()\|\[\]\|{}\)\|++\?\|--\?\|||\?\|!\|//\|[%&`/|]\)' transparent
  syn match elixirMixAtom "\%([a-zA-Z_]\w*[?!]\?\):\(:\)\@!" transparent
endif

if !hlexists('elixirComment')
  syn match elixirMixComment '#.*' transparent
endif

if !hlexists('elixirDocString')
  syn region elixirMixDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1" keepend transparent
  syn region elixirMixDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]{"                end="}"   skip="\\\\\|\\}"   keepend transparent
  syn region elixirMixDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]<"                end=">"   skip="\\\\\|\\>"   keepend transparent
  syn region elixirMixDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\["               end="\]"  skip="\\\\\|\\\]"  keepend transparent
  syn region elixirMixDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]("                end=")"   skip="\\\\\|\\)"   keepend transparent
  syn region elixirMixDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\z("\)+                 end=+\z1+ skip=+\\\\\|\\\z1+ keepend transparent
  syn region elixirMixDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\z("""\)+               end=+^\s*\z1+                keepend transparent
  syn region elixirMixDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\z('''\)+         end=+^\s*\z1+                keepend transparent
  syn region elixirMixDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\z("""\)+         end=+^\s*\z1+                keepend transparent
endif

if !hlexists('elixirVariable')
  syn match elixirMixVariable '@[a-z]\w*'
  syn match elixirMixVariable '&\d\+'
endif
