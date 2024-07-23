" Text objects lean heavily on syntax groups.
" In order to not have to depend on elixir.vim, we need to define our own for
" the groups that matter.  Most of these are copied from elixir.vim
" (https://github.com/elixir-editors/vim-elixir).

" Unavailable in elixir.vim
syn region elixirMixerLambda start="\<fn\>" end="\<end\>" keepend transparent
" syn region elixirMixerMap matchgroup=elixirMapDelimiter start="%{" end="}" transparent
syn region elixirMixerStruct matchgroup=elixirMixerStructDelimiters start="%\%(\w\|\.\)\+"hs=s+1 end="}"he=e-1 transparent
hi link elixirMixerStructDelimiters Type
syn region elixirMixerMap matchgroup=NONE start="%{" end="}" keepend transparent

if !hlexists('elixirSigil')
  syn match elixirMixerDelimEscape "\\[(<{\[)>}\]/\"'|]" transparent display contained contains=NONE

  syn region elixirMixerSigil matchgroup=elixirMixerSigilDelimiter start="\~\u\+\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1" contains=elixirMixerDelimEscape transparent
  syn region elixirMixerSigil matchgroup=elixirMixerSigilDelimiter start="\~\u\+{"                end="}"   skip="\\\\\|\\}"   contains=elixirMixerDelimEscape transparent
  syn region elixirMixerSigil matchgroup=elixirMixerSigilDelimiter start="\~\u\+<"                end=">"   skip="\\\\\|\\>"   contains=elixirMixerDelimEscape transparent
  syn region elixirMixerSigil matchgroup=elixirMixerSigilDelimiter start="\~\u\+\["               end="\]"  skip="\\\\\|\\\]"  contains=elixirMixerDelimEscape transparent
  syn region elixirMixerSigil matchgroup=elixirMixerSigilDelimiter start="\~\u\+("                end=")"   skip="\\\\\|\\)"   contains=elixirMixerDelimEscape transparent

  syn region elixirMixerSigil matchgroup=elixirMixerSigilDelimiter start="\~\l\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1"                                            transparent
  syn region elixirMixerSigil matchgroup=elixirMixerSigilDelimiter start="\~\l{"                end="}"   skip="\\\\\|\\}"   contains=elixirMixerRegexEscapePunctuation transparent
  syn region elixirMixerSigil matchgroup=elixirMixerSigilDelimiter start="\~\l<"                end=">"   skip="\\\\\|\\>"   contains=elixirMixerRegexEscapePunctuation transparent
  syn region elixirMixerSigil matchgroup=elixirMixerSigilDelimiter start="\~\l\["               end="\]"  skip="\\\\\|\\\]"  contains=elixirMixerRegexEscapePunctuation transparent
  syn region elixirMixerSigil matchgroup=elixirMixerSigilDelimiter start="\~\l("                end=")"   skip="\\\\\|\\)"   contains=elixirMixerRegexEscapePunctuation transparent
  syn region elixirMixerSigil matchgroup=elixirMixerSigilDelimiter start="\~\l\/"               end="\/"  skip="\\\\\|\\\/"  contains=elixirMixerRegexEscapePunctuation transparent

  " Sigils surrounded with heredoc
  syn region elixirMixerSigil matchgroup=elixirMixerSigilDelimiter start=+\~\a\z("""\)+ end=+^\s*\z1+ skip=+\\"+  transparent
  syn region elixirMixerSigil matchgroup=elixirMixerSigilDelimiter start=+\~\a\z('''\)+ end=+^\s*\z1+ skip=+\\'+  transparent
endif

if !hlexists('elixirRegexEscapePunctuation')
  syn match elixirMixerRegexEscapePunctuation "?\|\\.\|*\|\\\[\|\\\]\|+\|\\^\|\\\$\|\\|\|\\(\|\\)\|\\{\|\\}" contained transparent
endif

if !hlexists('elixirAtom')
  syn match elixirMixerAtom '\(:\)\@<!:\%([a-zA-Z_*]\w*\%([?!]\|=[>=]\@!\)\?\|<>\|===\?\|>=\?\|<=\?\)' contains=elixirAtom transparent
  syn match elixirMixerAtom '\(:\)\@<!:\%(<=>\|&&\?\|%\(()\|\[\]\|{}\)\|++\?\|--\?\|||\?\|!\|//\|[%&`/|]\)' contains=elixirAtom transparent
  syn match elixirMixerAtom "\%([a-zA-Z_]\w*[?!]\?\):\(:\)\@!" transparent
endif

if !hlexists('elixirComment')
  syn match elixirMixerComment '#.*' transparent
endif

if !hlexists('elixirDocString')
  syn region elixirMixerDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\z(/\|\"\|'\||\)" end="\z1" skip="\\\\\|\\\z1"  transparent
  syn region elixirMixerDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]{"                end="}"   skip="\\\\\|\\}"    transparent
  syn region elixirMixerDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]<"                end=">"   skip="\\\\\|\\>"    transparent
  syn region elixirMixerDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\["               end="\]"  skip="\\\\\|\\\]"   transparent
  syn region elixirMixerDocString matchgroup=NONE start="\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]("                end=")"   skip="\\\\\|\\)"    transparent
  syn region elixirMixerDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\z("\)+                 end=+\z1+ skip=+\\\\\|\\\z1+  transparent
  syn region elixirMixerDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\z("""\)+               end=+^\s*\z1+                 transparent
  syn region elixirMixerDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\z('''\)+         end=+^\s*\z1+                 transparent
  syn region elixirMixerDocString matchgroup=NONE start=+\%(@\w*doc\(\s\|(\)\+\)\@<=\~[Ss]\z("""\)+         end=+^\s*\z1+                 transparent
endif

if !hlexists('elixirVariable')
  syn match elixirMixerVariable '@[a-z]\w*'
  syn match elixirMixerVariable '&\d\+'
endif
