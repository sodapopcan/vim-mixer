vim9script

import autoload './cursor.vim'

export const HTML_MATCH_WORDS = '<!--:-->,<:>,<\@<=[ou]l\>[^>]*\%(>\|$\):<\@<=li\>:<\@<=/[ou]l>,<\@<=dl\>[^>]*\%(>\|$\):<\@<=d[td]\>:<\@<=/dl>,<\@<=\([^/!][^ \t>]*\)[^>]*\%(>\|$\):<\@<=/\1>'
export const ELIXIR_COMMENTSTRING = '#\ %s'
export const HEEX_COMMENTSTRING = '<%!--\ %s\ --%>'

if exists('g:loaded_matchit')
  augroup mixerMatchWords
    autocmd!
  augroup END
endif

export def SetMatchWords(): void
  if exists('b:match_words') && !exists('b:elixir_match_words')
    b:elixir_match_words = b:match_words
  endif

  if !exists('b:elixir_match_words')
    return
  endif

  const syn = cursor.OuterSynNameFull()

  if syn =~# 'Heex\|Surface' && syn !~# 'SigilDelimiter'
    b:match_words = HTML_MATCH_WORDS
  else
    b:match_words = b:elixir_match_words
  endif
enddef

export def SetCommentString(): void
  const syn = cursor.OuterSynNameFull()
  var str: string

  if syn =~# 'Heex\|Surface' && syn !~# 'SigilDelimiter'
    str = HEEX_COMMENTSTRING
  else
    str = ELIXIR_COMMENTSTRING
  endif

  # This check is done due to a now fixed bug: https://github.com/vim/vim/issues/15462
  if escape(&commentstring, ' ') !=# str
    const cursor_pos = getcurpos()
    exec 'setlocal commentstring=' .. str
    call setpos('.', cursor_pos)
  endif
enddef
