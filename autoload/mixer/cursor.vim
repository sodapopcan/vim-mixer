vim9script

# These functions return information about the buffer based on the current
# position of the cursor.

import autoload './util.vim'
import autoload './code.vim'

# const DEFDELEGATE_REGEX = '^\s*defdelegate\s\+\k\+(\=.*)\=\%(,\_.\{-}\(to:\|as:\)\s\+\([[:alnum:]:.]\+\)\%(,\_.\{-}\(to:\|as:\)\s\+\([[:alnum:]:.]\+\)\=\)\=\)'
const DEFDELEGATE_REGEX = '^\s*defdelegate\s\+\k\+(\=.*)\=\%(\%(,\_.\{-}\%(\(to:\|as:\)\s\+\([[:alnum:]:.]\+\)\)\)\{1,2}\)'

# Target is the word under the cursor, which may be a function or an alias.
# It returns a dictionary of the alias and optionally the function name.
export def Target(): dict<any>
  var fn: string = ''
  var token = expand('<cword>')
  var alias: string
  # This is the module name the target is defined in which is necessary to
  # account for nested defmodules.
  var context_alias: string = ''
  var is_delegate: bool = v:false

  # While <cexpr> works beautifully in Elixir files, it does not work in HEEx
  # files, so we have to do this manually.

  const view = winsaveview()

  try
    # Move to the beginning of the word.
    normal! wb

    const defdelegate = GetDefdelegate()

    if !empty(defdelegate)
      is_delegate = true
      fn = defdelegate['fn']
      alias = defdelegate['alias']
    else
      if Char(col('.') - 2) !~# '<\|\/'
        final aliases: list<string> = []

        if token =~# '^\u'
          fn = ''
          aliases->add(token)
        else
          fn = token
        endif

        const curr_line_num = line('.')

        while Char(col('.') - 1) == '.' && line('.') == curr_line_num
          normal! bb
          aliases->add(expand('<cword>'))
        endwhile

        alias = aliases->reverse()->join('.')
      else
        fn = token
      endif
    endif

    context_alias = GetContainingModule()
  catch
    return {}
  finally
    winrestview(view)

    return {
      fn: fn,
      alias: alias,
      alias_prefix: matchstr(alias, '\k\+'),
      context_alias: context_alias,
      is_delegate: is_delegate
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

export def GetDefdelegate(): dict<string>
  if getline('.') =~# '^\s*defdelegate' && !OnStringOrComment()
    final defdelegate: dict<string> = {}

    var lines: list<string> = [getline('.')->trim()]

    const pos = Pos()

    while getline('.') =~# ',$'
      normal! j
      lines->add(line('.')->getline()->trim())
    endwhile

    Set(pos)

    const line = lines->join(' ')

    defdelegate['alias'] = matchstr(line, 'to:\s\+\zs[[:alnum:].]\+')

    const as = matchstr(line, 'as:\s\+:\zs\k\+')

    if !empty(as)
      defdelegate['fn'] = as
    else
      defdelegate['fn'] = matchstr(line, '^\s*defdelegate\s\+\zs\k\+')
    endif

    return defdelegate
  else
    return {}
  endif
enddef

def GetContainingModule(): string
  const pos = Pos()

  while true && line('.') != 1
    search('^\s*defmodule\s\+\zs[[:keyword:].]\+\ze\s\+d', 'bW', 0, 0, OnStringOrComment)
    const candidate = expand('<cexpr>')
    const [start_pos, end_pos] = code.GetDef('defmodule', true)
    if util.InRange(pos, start_pos, end_pos)
      return candidate
    else
      normal! k0
    endif
  endwhile

  return ''
enddef
