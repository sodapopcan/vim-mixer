vim9script

import autoload './cursor.vim'
import autoload './util.vim'

const RESERVED = [
  'true', 'false', 'nil',
  'when', 'and', 'or', 'not', 'in',
  'fn',
  'do', 'end', 'catch', 'rescue', 'after', 'else'
]

const FUNC_CALL_REGEX = '\%(\<\%(\u\|:\)[A-Za-z_\.]\+\>\|\<\k\+\>\)\%(\s\|(\)'

const PAIRS = {
  '(': ')',
  ')': '(',
  '{': '}',
  '}': '{',
  '[': ']',
  ']': '[',
}


export def GetPair(delim: string): string
  return get(PAIRS, delim, 0)
enddef

export def FindDo(flags: string): list<number>
  return searchpos('\<do\>:\?', flags, 0, 0, () => cursor.OnStringOrComment())
enddef

export def FindDoBlockHead(do_pos: list<number>, flags: list<number>): list<number>
  # This is a bit nuts because we want to be able to find user-defined macro
  # calls, not just the builtins.

  # let stop = search('\%(\<end\>\|^\s*$\)', 'Wbn')
  const Skip = () => (
        expand('<cword>') =~ RESERVED ||
        !ParenInRange(do_pos) ||
        cursor.SynName() =~ 'Operator\|Number\|Atom\|String\|Tuple\|List\|Map\|Struct\|Sigil'
  )

  var func_pos = searchpos('\%(>\|=\|\%(\s\+\)\)\s\+\zs\<\k\+\>\s\+\<do\>:\?', 'Wb', line('.'))
  if line('.') == func_pos[0]
    # We're going to do the bone-headed thing here and walk up until we find
    # a non-blank line then see if it ends in a comma.
    normal! k
    while cursor.IsBlank()
      if line('.') == 1
        return [0, 0]
      endif
      normal! k
    endwhile

    if getline('.') !~ ',$'
      call cursor(func_pos)

      return func_pos
    endif
  endif

  # '\%(\<end\>\|\%(,$\)\)'
  # let start = '\%(\<end\>\s\+\)\@!\zs'
  const start = ''
  const no_follow = '\%(=\|\~\|<\|>\|\!\|&\||\|+\|\*\|\/\|-\|'.RESERVED.'\)\@!'

  return searchpos(start .. FUNC_CALL_REGEX .. no_follow, flags, 0, 0, Skip)
enddef

def ParenInRange(do_pos: list<number>): list<number>
  if expand('<cWORD>') =~ '\<\k\+\>('
    normal! f(
    const open_pos = cursor.Pos()
    const pair_pos = searchpairpos('(', '', ')', 'Wn', () => cursor.OnStringOrComment())
    normal! b

    return util.InRage(do_pos, open_pos, pair_pos)
  else
    return 1
  endif
enddef

export def DoFindEnd(): number
  call search('(\|{\|\[', 'W', line('.')) " Check if do block is a construct or function call

  if expand('<cWORD>') =~ '\<\k\+\>:'
    # Not a construct or function call
    return search(')\|,\|\n', 'W', 0, 0, {-> cursor.SynName() =~ 'String\|Comment\|Atom\|Sigil\|Number'})
  else
    var open_char = cursor.Char()
    var close_char = get_pair(open_char)

    if searchpair(escape(open_char, '['), '', escape(close_char, ']'), 'W', () => cursor.OnStringOrComment())
      if getline('.')[col('.')] ==# ','
        normal! l
      endif
    endif

    return 1
  endif
enddef

export def FindEndPos(func_pos: list<number>, do_pos: list<number>): list<number>
  cursor(func_pos)

  # If we're a block that was called with parens we're golden.
  if search('\%#'.expand('<cword>').'/zs(')
    var pair = searchpairpos('(', '', ')', '', () => cursor.OnStringOrComment())
    if v:operator ==# 'c'
      pair[1] -= 1
    endif

    return pair
  endif

  # The whole expression is wrapped in parens
  if search('(\%#'.expand('<cword>'), 'b')
    var pair = searchpairpos('(', '', ')', 'W', () => cursor.OnStringOrComment())
    pair[1] -= 1

    return pair
  endif

  cursor(do_pos)

  const Skip = () => cursor.OnStringOrComment() || cursor.IsLambdaEnd(do_pos)

  if expand('<cWORD>') ==# 'do:'
    cursor(do_pos)

    while DoFindEnd()
      if cursor.Char() ==# ','
        normal! w
        if expand('<cWORD>') =~ '\<\k\+\>:'
          continue
        else
          normal! geh

          return GetEndPos()
        endif
      elseif cursor.Char() ==# ')'
        var open_pos = searchpairpos('(', '', ')', 'Wbn', () => cursor.OnStringOrComment())
        if open_pos[0] == func_pos[0] && open_pos[1] == func_pos[1] - 1
          normal! h
        endif

        return GetEndPos()
      else
        return GetEndPos()
      endif
    endwhile
  else
    var pos = searchpairpos('\<do\>:\@!', '', '\<end\>', 'W', Skip)
    pos[1] += 2

    return pos
  endif
endfunction

def GetEndPos(): list<number>
  while cursor.Char() =~ '}\|\]'
    normal! h
  endwhile

  return cursor.Pos()
enddef

# TODO: Maybe take arity into account.
export def FindFirstFuncHead(def_pos: list<number>): list< number>
  var func_name = GetFuncName(def_pos)
  echom 'def\k*\s*'.func_name.'\>'
  while search('def\k*\s*'.func_name.'\>', 'Wb') | endwhile

  return cursor.Pos()
enddef

export def FindLastFuncHead(def_pos: list<number>): list<number>
  const func_name = GetFuncName(def_pos)
  while search('def\k*\s*\<\%(do_\)\='.func_name.'\>', 'W') | endwhile

  return cursor.Pos()
enddef

export def GetFuncName(def_pos: list<number>): list<number>
  cursor(def_pos)
  normal! w
  const func = matchstr(expand('<cword>'), '^\%(do_\)\=\zs\k*')
  normal! b

  return func
endfunction

export def IsLambdaEnd(do_pos: list<number>): number
  if expand('<cword>') ==# 'end'
    return searchpair('\<fn\>', '', '\<end\>\zs', 'Wbn', () => cursor.OnStringOrComment(), do_pos[0])
  endif

  return 0
endfunction

export def CheckForMeta(known_annotations: string): string
  const word = expand('<cword>')
  const WORD = expand('<cWORD>')

  return cursor.synstack_str() =~ 'Comment\|DocString' ||
         word =~ known_annotations ||
         WORD =~ known_annotations
endfunction
