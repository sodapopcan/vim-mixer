vim9script

import autoload './cursor.vim' as cur
import autoload './util.vim'

const EMPTY = [0, 0]
const EMPTY2 = [[0, 0], [0, 0]]
const EMPTY3 = [[0, 0], [0, 0], [0, 0]]

const reserved = [
  'when', 'and', 'or', 'not', 'in',
  'fn',
  'do', 'end', 'catch', 'rescue', 'after', 'else'
]

const RESERVED_REGEX = '\<' .. join(reserved, '\>\|\<') .. '\>'

const FUNC_CALL_REGEX = '\%(\<\%(\u\|:\)[A-Za-z_\.]\+\>\|\<\k\+\>\)\%(\s\|(\)'

export def GetBlock(inner: bool, include_meta: bool = v:true): list<list<number>>
  var view = winsaveview()

  var origin = cur.Pos()
  var start_pos = EMPTY
  var do_pos = EMPTY
  var end_pos = EMPTY
  var do = ''

  # First check if we are in `fn -> end`
  var fn_pos = HandleFn(origin, inner)

  if fn_pos == EMPTY3
    cur.Set(origin)

    # Then check if we are between a function call and a `do`
    do_pos = FindDo('Wc')

    var func_pos = FindDoBlockHead(do_pos, 'Wb')

    if util.InRange(origin, func_pos, do_pos)
      end_pos = FindEndPos(func_pos, do_pos)
    else
      cur.Set(origin)
      end_pos = EMPTY

      if expand('<cword>') =~# '\<end\>' && !cur.OnStringOrComment()
        do_pos = searchpairpos('\<do\>:\@!\|\<fn\>', '', '\<end\>\zs', 'Wb', () => cur.OnStringOrComment())
      else
        do_pos = FindDo('Wb')
      endif

      if do_pos == EMPTY
        winrestview(view)
        return EMPTY2
      endif

      func_pos = FindDoBlockHead(do_pos, 'Wb')

      end_pos = FindEndPos(func_pos, do_pos)
    endif

    if !util.InRange(origin, func_pos, end_pos)
      cur.Set(origin)

      do_pos = FindDo('W')
      func_pos = FindDoBlockHead(do_pos, 'Wbc')
      end_pos = FindEndPos(func_pos, do_pos)
    endif

    if func_pos == EMPTY
      winrestview(view)
      return EMPTY2
    endif

    if inner
      start_pos = copy(do_pos)
      start_pos[1] = 1
    else
      start_pos = copy(func_pos)
    endif

    cur.Set(do_pos)
    do = expand('<cWORD>')
  else
    [start_pos, do_pos, end_pos] = fn_pos
    do = '->'
  endif

  if !inner && include_meta
    cur.Set(start_pos)

    normal! b
    if cur.Char() !=# "="
      normal! w
    else
      normal! b
      if cur.Char() =~ ')\|}\|\]'
        var close_char = cur.Char()
        var open_char = util.GetPair(close_char)
        start_pos = searchpairpos(open_char, '', close_char, 'Wb', () => cur.OnStringOrComment())
        normal! F%
        start_pos[1] = col('.')
      endif
    endif

    while getline(line('.') - 1) =~ '^\%(\s\+\)\?#'
      normal! k
    endwhile

    start_pos = [line('.'), 1]

    cur.Set(do_pos)
  endif

  if inner && do =~# 'do:\|->'
    if do ==# 'do:'
      start_pos[0] = do_pos[0]
      # Clear `do:` When switching to insert, leaving a space after it.
      start_pos[1] = do_pos[1] + (v:operator ==# 'c' ? 4 : 3)
    elseif do ==# '->'
      # Clear `->` When switching to insert, leaving a space after it.
      start_pos[1] = do_pos[1] + (v:operator ==# 'c' ? 3 : 2)
      [start_pos, end_pos] = AdjustBlockRegion(inner, do, start_pos, end_pos)
    endif
  else
    [start_pos, end_pos] = AdjustBlockRegion(inner, do, start_pos, end_pos)
  endif

  return [start_pos, end_pos]
enddef

export def GetDef(kwd: string, inner: bool = false, include_annotations: bool = false): list<list<number>>
  var known_annotations = '@doc\>\|@spec\>\|@tag\>\|@requirements\>\|\<attr\>\|\<slot\>'
  var user_annotations: string = get(g:, 'mixer_known_annotations', '')

  if !empty(user_annotations)
    known_annotations = join([known_annotations, user_annotations], '\|')
  endif

  const Skip = () => cur.SynName() =~ 'String\|Comment'
  var view = winsaveview()
  var keyword = '\<\%(' .. escape(kwd, '|') .. '\)\>'
  var cursor_origin = cur.Pos()

  # Being in the gutter of a def line is considered in range
  normal! ^
  var cursor_start = cur.Pos()

  if CheckForMeta(known_annotations)
    search(keyword, 'W', 0, 0, Skip)
  endif

  # Search backward
  var def_pos = searchpos(keyword, 'Wcb', 0, 0, Skip)
  var do_pos = FindDo('W')
  var end_pos = FindEndPos(def_pos, do_pos)

  if !util.InRange(cursor_start, def_pos, end_pos) || do_pos == EMPTY
    winrestview(view)

    def_pos = searchpos(keyword, 'W', 0, 0, Skip)
  endif

  if def_pos == EMPTY
    winrestview(view)
    return EMPTY2
  endif

  if !inner && include_annotations
    def_pos = FindFirstFuncHead(def_pos)
  endif

  cur.Set(def_pos)

  do_pos = FindDo('W')

  var first_head_has_keyword_do = expand('<cWORD>') ==# 'do:'

  cur.Set(def_pos)

  if !inner && include_annotations
    FindLastFuncHead(def_pos)
    do_pos = FindDo('Wc')
  endif

  var start_pos = copy(def_pos)
  end_pos = FindEndPos(def_pos, do_pos)

  cur.Set(def_pos)

  # Look for the meta
  if !inner && include_annotations
    const func_name = GetFuncName(def_pos)

    const stopline = max([1, search('\<end\>\|def\%(macro\)\?p\? \%(' .. func_name .. '\)\@!', 'Wbn', 0, 0, () => cur.SynName() =~ 'String\|Comment\|DocString\|markdown')])

    search('^\s*$', 'Wb', stopline, 0, () => cur.SynName() =~ 'String\|Comment\|DocString\|markdown')

    while search(known_annotations, 'Wb', stopline) > 0 | endwhile

    start_pos = cur.Pos()
  endif

  if inner && first_head_has_keyword_do
    # Clear `do:` When switching to insert, leave a space after it otherwise do not.
    start_pos[0] = do_pos[0]
    start_pos[1] = do_pos[1] + (v:operator ==# 'c' ? 4 : 3)
  else
    start_pos[1] = 1
    [start_pos, end_pos] = AdjustBlockRegion(inner, 'do', start_pos, end_pos)
  endif

  return [start_pos, end_pos]
enddef

export def GetComment(): list<list<number>>
  var view = winsaveview()
  var cursor_origin = cur.Pos()

  normal $

  if !cur.OnComment()
    winrestview(view)
    return EMPTY2
  endif

  var comment_type = cur.OuterSynName()

  while cur.OnComment() && comment_type == cur.OuterSynName()
    if line('.') == 1
      break
    endif

    normal k$
  endwhile

  if !cur.OnComment() || comment_type != cur.OuterSynName()
    normal j$
  endif

  var start_lnr = line('.')
  var start_col = 0

  cur.Set(cursor_origin)

  normal $

  while cur.OnComment() && comment_type ==# cur.OuterSynName()
    if line('.') == line('$')
      break
    endif

    normal j$
  endwhile

  if !cur.OnComment() || comment_type != cur.OuterSynName()
    normal k$
  endif

  var end_lnr = line('.')
  var end_col: number

  if inner && comment_type ==# 'DocString'
    start_lnr += 1
    end_lnr -= 1
    end_col = len(getline(end_lnr))
  else
    end_col = len(getline(end_lnr)) + 1
  endif

  return [[start_lnr, start_col], [end_lnr, end_col]]
enddef

def AdjustBlockRegion(inner: bool, do: string, start_pos: list<number>, end_pos: list<number>): list<list<number>>
  if v:operator ==# 'c' && !inner
    # We want to leave a blank line in insert mode so let's bail because we
    # don't want to adjust anything.
    return [start_pos, end_pos]
  endif

  var [start_lnr, start_col] = start_pos
  var [end_lnr, end_col] = end_pos

  if inner
    if start_lnr != end_lnr
      start_lnr += 1
      end_lnr -= 1
    elseif do ==# '->'
      end_col -= 4
    endif

    if v:operator ==# 'c'
      exec ':' .. (start_lnr + 1)

      if do !=# '->'
        start_col = indent(start_lnr) + 1
        end_col = len(getline(end_lnr))
      endif
    else
      if do !=# '->'
        end_col = len(getline(end_lnr)) + 1 # Include \n
      endif
      exec ':' .. start_lnr
    endif
  else
    [start_lnr, start_col] = AdjustWhitespace([start_lnr, start_col])

    if start_col == 0
      start_col = 1
    endif

    if do ==# 'do'
      end_col = len(getline(end_lnr)) + 1 # Include \n
    endif

    exec ':' .. start_lnr
  endif

  return [[start_lnr, start_col], [end_lnr, end_col]]
enddef

def AdjustWhitespace(start_pos: list<number>): list<number>
  var [start_lnr, start_col] = start_pos

  var start_line = getline(start_lnr)
  var prev_blank = util.IsBlank(getline(start_lnr - 1))
  var offset = 0

  if start_col > 2
    offset = start_col - 2
  else
    offset = 0
  endif

  const empty_gutter = start_line[0 : offset] =~ '^\s*$'

  if start_lnr > 1 && prev_blank && empty_gutter
    start_lnr -= 1
    start_col = 1
  elseif start_lnr > 1 && empty_gutter
    start_col = 1
  endif

  return [start_lnr, start_col]
enddef

def HandleFn(origin: list<number>, inner: bool): list<list<number>>
  var fn_pos = searchpos('\<fn\>', 'Wbc', 0, 0, () => cur.OnStringOrComment())
  var do_pos = EMPTY
  var end_pos = EMPTY
  var do: string

  if fn_pos == EMPTY
    return EMPTY3
  else
    do_pos = searchpos('->', 'Wn', 0, 0, () => cur.OnStringOrComment())
    do = '->'
    end_pos = searchpairpos('\<fn\>', '', '\<end\>', 'W', () => cur.OnStringOrComment())
    end_pos[1] += 2

    if util.InRange(origin, fn_pos, end_pos)
      return [fn_pos, do_pos, end_pos]
    else
      return EMPTY3
    endif
  endif
enddef

def FindDo(flags: string): list<number>
  return searchpos('\<do\>:\?', flags, 0, 0, () => cur.OnStringOrComment())
enddef

def FindDoBlockHead(do_pos: list<number>, flags: string): list<number>
  # This is a bit nuts because we want to be able to find user-defined macro
  # calls, not just the builtins.

  # let stop = search('\%(\<end\>\|^\s*$\)', 'Wbn')
  const Skip = () => (
    expand('<cword>') =~ RESERVED_REGEX ||
    !ParenInRange(do_pos) ||
    cur.SynName() =~ 'Operator\|Number\|Atom\|String\|Tuple\|List\|Map\|Struct\|Sigil'
  )

  var func_pos = searchpos('\%(>\|=\|\%(\s\+\)\)\s\+\zs\<\k\+\>\s\+\<do\>:\?', 'Wb', line('.'))

  if line('.') == func_pos[0]
    # We're going to do the bone-headed thing here and walk up until we find
    # a non-blank line then see if it ends in a comma.
    normal! k
    while cur.IsBlank()
      if line('.') == 1
        return [0, 0]
      endif
      normal! k
    endwhile

    if getline('.') !~ ',$'
      call cur.Set(func_pos)

      return func_pos
    endif
  endif

  # '\%(\<end\>\|\%(,$\)\)'
  # let start = '\%(\<end\>\s\+\)\@!\zs'
  const start = ''
  const no_follow = '\%(=\|\~\|<\|>\|\!\|&\||\|+\|\*\|\/\|-\|' .. RESERVED_REGEX .. '\)\@!'

  return searchpos(start .. FUNC_CALL_REGEX .. no_follow, flags, 0, 0, Skip)
enddef

def ParenInRange(do_pos: list<number>): bool
  if expand('<cWORD>') =~ '\<\k\+\>('
    normal! f(
    const open_pos = cur.Pos()
    const pair_pos = searchpairpos('(', '', ')', 'Wn', () => cur.OnStringOrComment())
    normal! b

    return util.InRange(do_pos, open_pos, pair_pos)
  else
    return true
  endif
enddef

def DoFindEnd(): bool
  search('(\|{\|\[', 'W', line('.')) # Check if do block is a construct or function call

  if expand('<cWORD>') =~ '\<\k\+\>:'
    # Not a construct or function call
    return search(')\|,\|\n', 'W', 0, 0, () => cur.SynName() =~ 'String\|Comment\|Atom\|Sigil\|Number') > 0
  else
    var open_char = cur.Char()
    var close_char = util.GetPair(open_char)

    if searchpair(escape(open_char, '['), '', escape(close_char, ']'), 'W', () => cur.OnStringOrComment()) > 0
      if getline('.')[col('.')] ==# ','
        normal! l
      endif
    endif

    return true
  endif
enddef

# TODO: Maybe take arity into account.
def FindFirstFuncHead(def_pos: list<number>): list< number>
  var func_name = GetFuncName(def_pos)
  while search('def\k*\s*' .. func_name .. '\>', 'Wb') > 0 | endwhile

  return cur.Pos()
enddef

def FindLastFuncHead(def_pos: list<number>): list<number>
  const func_name = GetFuncName(def_pos)
  while search('def\k*\s*\<\%(do_\)\=' .. func_name .. '\>', 'W') > 0 | endwhile

  return cur.Pos()
enddef

def GetFuncName(def_pos: list<number>): string
  cur.Set(def_pos)
  normal! w
  const func = matchstr(expand('<cword>'), '^\%(do_\)\=\zs\k*')
  normal! b

  return func
enddef

def FindEndPos(func_pos: list<number>, do_pos: list<number>): list<number>
  cur.Set(func_pos)

  # If we're a block that was called with parens we're golden.
  if search('\%#' .. expand('<cword>') .. '/zs(') > 0
    var pair = searchpairpos('(', '', ')', '', () => cur.OnStringOrComment())
    if v:operator ==# 'c'
      pair[1] -= 1
    endif

    return pair
  endif

  # The whole expression is wrapped in parens
  if search('(\%#' .. expand('<cword>'), 'b') > 0
    var pair = searchpairpos('(', '', ')', 'W', () => cur.OnStringOrComment())
    pair[1] -= 1

    return pair
  endif

  cur.Set(do_pos)

  const Skip = () => cur.OnStringOrComment() || IsLambdaEnd(do_pos)

  if expand('<cWORD>') ==# 'do:'
    cur.Set(do_pos)

    while DoFindEnd()
      if cur.Char() ==# ','
        normal! w
        if expand('<cWORD>') =~ '\<\k\+\>:'
          continue
        else
          normal! geh

          return GetEndPos()
        endif
      elseif cur.Char() ==# ')'
        var open_pos = searchpairpos('(', '', ')', 'Wbn', () => cur.OnStringOrComment())
        if open_pos[0] == func_pos[0] && open_pos[1] == func_pos[1] - 1
          normal! h
        endif

        return GetEndPos()
      else
        return GetEndPos()
      endif
    endwhile

    return [0, 0]
  else
    var pos = searchpairpos('\<do\>:\@!', '', '\<end\>', 'W', Skip)
    pos[1] += 2

    return pos
  endif
enddef

def GetEndPos(): list<number>
  while cur.Char() =~ '}\|\]'
    normal! h
  endwhile

  return cur.Pos()
enddef

def IsLambdaEnd(do_pos: list<number>): bool
  if expand('<cword>') ==# 'end'
    return searchpair('\<fn\>', '', '\<end\>\zs', 'Wbn', () => cur.OnStringOrComment(), do_pos[0]) > 0
  endif

  return 0
enddef

def CheckForMeta(known_annotations: string): bool
  const word = expand('<cword>')
  const WORD = expand('<cWORD>')

  return cur.SynstackStr() =~ 'Comment\|DocString' ||
    word =~ known_annotations ||
    WORD =~ known_annotations
enddef
