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
