" Text objects lean heavily on syntax groups.
" In order to not have to depend on elixir.vim, we need to define our own for
" the groups that matter.  Most of these are copied from elixir.vim
" (https://github.com/elixir-editors/vim-elixir).

" Unavailable in elixir.vim
syn region elixirMixLambda start="\<fn\>" end="\<end\>" keepend transparent
" syn region elixirMixMap matchgroup=elixirMapDelimiter start="%{" end="}" transparent
syn region elixirMixStruct matchgroup=elixirMixStructDelimiters start="%\%(\w\|\.\)\+"hs=s+1 end="}"he=e-1 transparent
hi link elixirMixStructDelimiters Type
syn region elixirMixMap matchgroup=NONE start="%{" end="}" keepend transparent
syn region elixirArguments start="(" end=")" contained contains=elixirMixStruct,elixirMixMap transparent
" syn region elixirMixTuple matchgroup=NONE start="\(\w\|#\)\@<!{" end="}" transparent

if !hlexists('elixirSigil')
  syn match elixirMixDelimEscape "\\[(<{\[)>}\]/\"'|]" transparent display contained contains=NONE

  syn region elixirMixSigil matchgroup=elixirMixSigilDelimiter start="\~\u\+\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1" contains=elixirMixDelimEscape transparent
  syn region elixirMixSigil matchgroup=elixirMixSigilDelimiter start="\~\u\+{"                end="}"   skip="\\\\\|\\}"   contains=elixirMixDelimEscape transparent
  syn region elixirMixSigil matchgroup=elixirMixSigilDelimiter start="\~\u\+<"                end=">"   skip="\\\\\|\\>"   contains=elixirMixDelimEscape transparent
  syn region elixirMixSigil matchgroup=elixirMixSigilDelimiter start="\~\u\+\["               end="\]"  skip="\\\\\|\\\]"  contains=elixirMixDelimEscape transparent
  syn region elixirMixSigil matchgroup=elixirMixSigilDelimiter start="\~\u\+("                end=")"   skip="\\\\\|\\)"   contains=elixirMixDelimEscape transparent

  syn region elixirMixSigil matchgroup=elixirMixSigilDelimiter start="\~\l\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1"                                                              transparent
  syn region elixirMixSigil matchgroup=elixirMixSigilDelimiter start="\~\l{"                end="}"   skip="\\\\\|\\}"   transparent
  syn region elixirMixSigil matchgroup=elixirMixSigilDelimiter start="\~\l<"                end=">"   skip="\\\\\|\\>"   transparent
  syn region elixirMixSigil matchgroup=elixirMixSigilDelimiter start="\~\l\["               end="\]"  skip="\\\\\|\\\]"  transparent
  syn region elixirMixSigil matchgroup=elixirMixSigilDelimiter start="\~\l("                end=")"   skip="\\\\\|\\)"   transparent
  syn region elixirMixSigil matchgroup=elixirMixSigilDelimiter start="\~\l\/"               end="\/"  skip="\\\\\|\\\/"  transparent

  " Sigils surrounded with heredoc
  syn region elixirMixSigil matchgroup=elixirMixSigilDelimiter start=+\~\a\z("""\)+ end=+^\s*\z1+ skip=+\\"+  transparent
  syn region elixirMixSigil matchgroup=elixirMixSigilDelimiter start=+\~\a\z('''\)+ end=+^\s*\z1+ skip=+\\'+  transparent
endif

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
