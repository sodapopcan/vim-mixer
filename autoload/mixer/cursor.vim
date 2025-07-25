vim9script

# These functions return information about the buffer based on the current
# position of the cursor.

import autoload './util.vim'

# Target is the word under the cursor, which may be a function or an alias.
# It returns a dictionary of the alias and optionally the function name.
export def Target(): dict<string>
  var fn = expand('<cword>')
  final aliases: list<string> = []
  # This is the module name the target is defined in which is necessary to
  # account for nested defmodules.
  var context_alias: string = ''

  # While <cexpr> works beautifully in Elixir files, it does not work in HEEx
  # files, so we have to do this manually.
  const view = winsaveview()

  try
    # Move to the beginning of the word.
    normal! wb

    if Char(col('.') - 2) != '<'
      const curr_line_num = line('.')

      while Char(col('.') - 1) == '.' && line('.') == curr_line_num
        normal! bb
        aliases->add(expand('<cword>'))
      endwhile

      search('^\s*defmodule\s\+\zs[[:keyword:].]\+\ze\s\+d', 'bWe', 0, 0, OnStringOrComment)
      context_alias = expand('<cexpr>')
    endif
  catch
    return {}
  finally
    winrestview(view)

    return {
      fn: fn,
      alias: aliases->copy()->reverse()->join('.'),
      alias_prefix: aliases[-1],
      context_alias: context_alias
    }
  endtry
enddef

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

  return synstack(line, col)
    -> map((_, v) => synIDattr(v, 'name'))
    -> join(' ')
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

export def OnHEEx(): bool
  return OuterSynName() =~ 'Heex' && SynstackStr() !~ 'heexExpression'
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
