vim9script

# These functions return information about the buffer based on the current
# position of the cursor.

import autoload './util.vim'

export def Char(...pos: list<number>): string
  if len(pos)
    return getline('.')[pos[0] - 1]
  else
    return getline('.')[col('.') - 1]
  endif
enddef

export def SynName(...pos: list<number>): string
  if 0
    const [line, col] = pos
  else
    const [line, col] = GetCursorPos()
  endif

  const names = map(synstack(line, col), 'synIDattr(v:val,"name")')

  if len(names)
    return util.Sub(names[-1], 'elixir', '')
  else
    return ''
  endif
enddef

export def InGutter(): bool
  const leading_whitespace_len = len(matchstr(getline('.'), '^\s\+'))

  return col('.') <= leading_whitespace_len
enddef

export def OuterSynName(): string
  const term = GetTerms()

  if empty(terms)
    return ''
  endif

  return util.Sub(util.sub(terms[0], 'elixir', ''), 'Delimiter', '')
enddef

export def SynstackStr(): string
  return join(GetTerms(), ',')
enddef

def GetTerms(): list<string>
  const stack = synstack(line('.'), col('.'))
  const names = map(stack, (_, v) => synIDattr(v, 'name'))

  return filter(names, (_, v) => v !=# 'elixirBlock')
enddef

export def OnComment(): bool
  return index(['Comment', 'DocString', 'DocStringDelimiter'], OuterSynName()) > -1
enddef

export def OnSringOrComment(): bool
  return SynName() =~ 'String\|Comment\|CharList'
enddef

export def Pos(): list<number>
  return [line('.'), col('.')]
enddef

export def PrevLine(): string
  return getline(line('.') - 1)
enddef
