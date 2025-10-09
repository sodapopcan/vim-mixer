vim9script

# These functions return information about the buffer based on the current
# position of the cursor.

import autoload './util.vim'

# Just a wrapper around `cursor()` so that we don't have to alias this file's import.
export def Set(pos: list<number>)
  cursor(pos)
enddef

export def Char(...pos: list<number>): string
  if len(pos) > 0
    return getline('.')[pos[0] - 1]
  else
    return getline('.')[col('.') - 1]
  endif
enddef

export def SynName(): string
  const [line, col] = Pos()

  const names = map(synstack(line, col), (_, v) => synIDattr(v, "name"))

  if len(names) > 0
    return util.Sub(names[-1], 'elixir', '')
  else
    return ''
  endif
enddef

export def InGutter(): bool
  return col('.') <= getline('.')->matchstr('^\s\+')->len()
enddef

export def IsBlank(): bool
  return getline('.') =~ '^\s*$'
enddef

export def OuterSynName(): string
  var terms = GetTerms()

  if empty(terms)
    return ''
  endif

  return terms[0]
    -> util.Sub('elixir', '')
    -> util.Sub('Delimiter', '')
enddef

# Need to do something about this-we do not need both of these functions.
export def OuterSynNameFull(): string
  var terms = GetTerms()

  if empty(terms)
    return ''
  endif

  return terms[0]
enddef

export def SynstackStr(): string
  return join(GetTerms(), ',')
enddef

def GetTerms(): list<string>
  return synstack(line('.'), col('.'))
    -> map((_, v) => synIDattr(v, 'name'))
    -> filter((_, v) => v !=# 'elixirBlock')
enddef

export def OnComment(): bool
  return index(['Comment', 'DocString', 'DocStringDelimiter'], OuterSynName()) > -1
enddef

export def OnStringOrComment(): bool
  return SynName() =~ 'String\|Comment\|CharList'
enddef

export def Pos(): list<number>
  return [line('.'), col('.')]
enddef

export def PrevLine(): string
  return getline(line('.') - 1)
enddef

export def NextLine(): string
  return getline(line('.') + 1)
enddef

export def FunctionName(): string
  const view = winsaveview()

  var name = ''

  if getline('.') =~ '^\s*\<def\%(p\|macro\|macrop\)\>'
    name = getline('.')->matchstr('^\s*\<def\%(p\|delegate\|macro\|macrop\)\>\s\+\zs\k\+')
  else
    var cur_pos = [line('.'), 0]
    var def_lnum = search('\<def\>', 'Wbc', 0, 0, OnStringOrComment)
    searchpos('\<do\>', 'W', 0, 0, OnStringOrComment)
    var end_pos = searchpairpos('\<do\>:\@!\|\<fn\>', '', '\<end\>', 'W', OnStringOrComment)

    if util.InRange(cur_pos, [def_lnum, 1], end_pos)
      name = getline(def_lnum)->matchstr('\s*def\s\+\zs\k\+')
    else
      def_lnum = search('\<def\>', 'Wc', 0, 0, OnStringOrComment)
      searchpos('\<do\>', 'W', 0, 0, OnStringOrComment)
      end_pos = searchpairpos('\<do\>\:\@!|\<fn\>', '', '\<end\>', 'W', OnStringOrComment)

      if util.InRange(cur_pos, [def_lnum, 1], end_pos)
        name = getline(def_lnum)->matchstr('\s*def\s\+\zs\k\+')
      endif
    endif
  endif

  winrestview(view)

  return name
enddef
