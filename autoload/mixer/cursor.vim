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

# Returns a dict with info about the current function:
# {
#   name: <string>,
#   def_pos: list<integer>,
#   do_pos: list<integer>,
#   end_pos: list<integer>
# }
#
export def CurrentFunction(): dict<any>
  const Skip = () => OnStringOrComment()
  const cursor_origin = Pos()
  const view = winsaveview()

  final func = {
    name: "",
    def_pos: [0, 0],
    do_pos: [0, 0],
    end_pos: [0, 0]
  }


  func.def_pos = searchpos('\s*\zs\<def\>', 'Wbc', 0, 0, Skip)
  func.do_pos = searchpos('\<do\>:\@!')

  if func.def_pos != [0, 0]
    func.end_pos = searchpairpos('\<do\>:\@!\|\<fn\>', '', '\<end\>', 'W', Skip)
    func.end_pos[1] += 2
  else
    winrestview(view)

    return func
  endif

  if util.InRange(cursor_origin, func.def_pos, func.end_pos)
    Set(func.def_pos)
    normal! W
    func.name = expand('<cword>')
    winrestview(view)

    return func
  else
    winrestview(view)

    return func
  endif
enddef

export def InFunction(func: string): bool
  const current_func = CurrentFunction()

  return util.InRange(Pos(), current_func.do_pos, current_func.end_pos)
enddef

# TODO: Handle keyword syntax
export def InRender(): bool
  const cursor_origin = cursor.Pos()
  const view = winsaveview()
  var def_pos = [0, 0]
  var do_pos = [0, 0]
  var end_pos = [0, 0]

  def_pos = searchpos(RENDER_REGEX, 'Wbc', 0, 0, Skip)

  if def_pos == [0, 0]
    return false
  endif

  end_pos = searchpairpos('\<def\>\|\<fn\>', '', '\<end\>', 'W', Skip)

  winrestview(view)

  return util.InRange(cursor_origin, def_pos, end_pos)
enddef
