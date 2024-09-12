vim9script

import autoload './cursor.vim'
import autoload './util.vim'

# Map Definitions {{{1

export def Define()
  const def = get(g:, 'mixer_textobj_def', 'f')
  const def_with_meta = get(g:, 'mixer_textobj_def_with_meta', 'F')
  const block = get(g:, 'mixer_textobj_block', 'd')
  const block_with_meta = get(g:, 'mixer_textobj_block_with_meta', 'D')
  const module = get(g:, 'mixer_textobj_module', 'M')
  const map = get(g:, 'mixer_textobj_map', 'm')
  const sigil = get(g:, 'mixer_textobj_sigil', 'S')
  const comment = get(g:, 'mixer_textobj_comment', 'c')
  const quote = get(g:, 'mixer_textobj_quote', 'q')

  const defregex = 'defp\=\|defmacrop\=\|defnp\='

  exec "vnoremap <silent> <buffer> i" .. def .. " :\<c-u>call <sid>TextObj_def('" .. defregex .. "', v:true, v:false)\<cr>"
  exec "vnoremap <silent> <buffer> a" .. def .. " :\<c-u>call <sid>TextObj_def('" .. defregex .. "', v:false, v:false)\<cr>"
  exec "onoremap <silent> <buffer> i" .. def .. " :\<c-u>call <sid>TextObj_def('" .. defregex .. "', v:true, v:false)\<cr>"
  exec "onoremap <silent> <buffer> a" .. def .. " :\<c-u>call <sid>TextObj_def('" .. defregex .. "', v:false, v:false)\<cr>"

  exec "vnoremap <silent> <buffer> i" .. def_with_meta .. " :\<c-u>call <sid>TextObj_def('" .. defregex .. "', v:true, v:true)\<cr>"
  exec "vnoremap <silent> <buffer> a" .. def_with_meta .. " :\<c-u>call <sid>TextObj_def('" .. defregex .. "', v:false, v:true)\<cr>"
  exec "onoremap <silent> <buffer> i" .. def_with_meta .. " :\<c-u>call <sid>TextObj_def('" .. defregex .. "', v:true, v:true)\<cr>"
  exec "onoremap <silent> <buffer> a" .. def_with_meta .. " :\<c-u>call <sid>TextObj_def('" .. defregex .. "', v:false, v:true)\<cr>"

  exec "vnoremap <silent> <buffer> i" .. module .. " :\<c-u>call <sid>TextObj_def('defmodule', v:true, v:false)\<cr>"
  exec "vnoremap <silent> <buffer> a" .. module .. " :\<c-u>call <sid>TextObj_def('defmodule', v:false, v:false)\<cr>"
  exec "onoremap <silent> <buffer> i" .. module .. " :\<c-u>call <sid>TextObj_def('defmodule', v:true, v:false)\<cr>"
  exec "onoremap <silent> <buffer> a" .. module .. " :\<c-u>call <sid>TextObj_def('defmodule', v:false, v:false)\<cr>"

  exec "vnoremap <silent> <buffer> i" .. quote .. " :\<c-u>call <sid>TextObj_def('quote', v:true, v:true)\<cr>"
  exec "vnoremap <silent> <buffer> a" .. quote .. " :\<c-u>call <sid>TextObj_def('quote', v:false, v:true)\<cr>"
  exec "onoremap <silent> <buffer> i" .. quote .. " :\<c-u>call <sid>TextObj_def('quote', v:true, v:true)\<cr>"
  exec "onoremap <silent> <buffer> a" .. quote .. " :\<c-u>call <sid>TextObj_def('quote', v:false, v:true)\<cr>"

  exec "vnoremap <silent> <buffer> i" .. block .. " :\<c-u>call <sid>TextObj_block(v:true, v:false)\<cr>"
  exec "vnoremap <silent> <buffer> a" .. block .. " :\<c-u>call <sid>TextObj_block(v:false, v:false)\<cr>"
  exec "onoremap <silent> <buffer> i" .. block .. " :\<c-u>call <sid>TextObj_block(v:true, v:false)\<cr>"
  exec "onoremap <silent> <buffer> a" .. block .. " :\<c-u>call <sid>TextObj_block(v:false, v:false)\<cr>"

  exec "vnoremap <silent> <buffer> i" .. block_with_meta .. " :\<c-u>call <sid>TextObj_block(v:true, v:false)\<cr>"
  exec "vnoremap <silent> <buffer> a" .. block_with_meta .. " :\<c-u>call <sid>TextObj_block(v:false, v:true)\<cr>"
  exec "onoremap <silent> <buffer> i" .. block_with_meta .. " :\<c-u>call <sid>TextObj_block(v:true, v:false)\<cr>"
  exec "onoremap <silent> <buffer> a" .. block_with_meta .. " :\<c-u>call <sid>TextObj_block(v:false, v:true)\<cr>"

  exec "vnoremap <silent> <buffer> i" .. comment .. " :\<c-u>call <sid>TextObj_comment(v:true)\<cr>"
  exec "vnoremap <silent> <buffer> a" .. comment .. " :\<c-u>call <sid>TextObj_comment(v:false)\<cr>"
  exec "onoremap <silent> <buffer> i" .. comment .. " :\<c-u>call <sid>TextObj_comment(v:true)\<cr>"
  exec "onoremap <silent> <buffer> a" .. comment .. " :\<c-u>call <sid>TextObj_comment(v:false)\<cr>"

  exec "vnoremap <silent> <buffer> i" .. map .. " :\<c-u>call <sid>TextObj_map(v:true)\<cr>"
  exec "vnoremap <silent> <buffer> a" .. map .. " :\<c-u>call <sid>TextObj_map(v:false)\<cr>"
  exec "onoremap <silent> <buffer> i" .. map .. " :\<c-u>call <sid>TextObj_map(v:true)\<cr>"
  exec "onoremap <silent> <buffer> a" .. map .. " :\<c-u>call <sid>TextObj_map(v:false)\<cr>"

  exec "vnoremap <silent> <buffer> i" .. sigil .. " :\<c-u>call <sid>TextObj_sigil(v:true)\<cr>"
  exec "vnoremap <silent> <buffer> a" .. sigil .. " :\<c-u>call <sid>TextObj_sigil(v:false)\<cr>"
  exec "onoremap <silent> <buffer> i" .. sigil .. " :\<c-u>call <sid>TextObj_sigil(v:true)\<cr>"
  exec "onoremap <silent> <buffer> a" .. sigil .. " :\<c-u>call <sid>TextObj_sigil(v:false)\<cr>"
enddef

# Constants {{{1

const EMPTY = [0, 0]
const EMPTY2 = [[0, 0], [0, 0]]
const EMPTY3 = [[0, 0], [0, 0], [0, 0]]

const reserved = [
  'when', 'and', 'or', 'not', 'in',
  'fn',
  'do', 'end', 'catch', 'rescue', 'after', 'else'
]

const RESERVED = '\<' .. join(reserved, '\>\|\<') .. '\>'

const FUNC_CALL_REGEX = '\%(\<\%(\u\|:\)[A-Za-z_\.]\+\>\|\<\k\+\>\)\%(\s\|(\)'

# Common {{{1

def SelectObj(start_pos: list<number>, end_pos: list<number>)
  const [start_lnr, start_col] = start_pos
  const [end_lnr, end_col] = end_pos

  setpos("'<", [0, start_lnr, start_col, 0])
  setpos("'>", [0, end_lnr, end_col, 0])

  normal! gv
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

# def/fn/do/end/etc Helpers {{{1

def AdjustBlockRegion(inner: bool, do: string, start_pos: list<number>, end_pos: list<number>): list<list<number>>
  if v:operator ==# 'c' && !inner
    # We want a blank line left for insert mode so don't adjust anything
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

def FindDo(flags: string): list<number>
  return searchpos('\<do\>:\?', flags, 0, 0, () => cursor.OnStringOrComment())
enddef

def FindDoBlockHead(do_pos: list<number>, flags: string): list<number>
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
      call cursor.Set(func_pos)

      return func_pos
    endif
  endif

  # '\%(\<end\>\|\%(,$\)\)'
  # let start = '\%(\<end\>\s\+\)\@!\zs'
  const start = ''
  const no_follow = '\%(=\|\~\|<\|>\|\!\|&\||\|+\|\*\|\/\|-\|' .. RESERVED .. '\)\@!'

  return searchpos(start .. FUNC_CALL_REGEX .. no_follow, flags, 0, 0, Skip)
enddef

def ParenInRange(do_pos: list<number>): bool
  if expand('<cWORD>') =~ '\<\k\+\>('
    normal! f(
    const open_pos = cursor.Pos()
    const pair_pos = searchpairpos('(', '', ')', 'Wn', () => cursor.OnStringOrComment())
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
    return search(')\|,\|\n', 'W', 0, 0, () => cursor.SynName() =~ 'String\|Comment\|Atom\|Sigil\|Number') > 0
  else
    var open_char = cursor.Char()
    var close_char = util.GetPair(open_char)

    if searchpair(escape(open_char, '['), '', escape(close_char, ']'), 'W', () => cursor.OnStringOrComment()) > 0
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

  return cursor.Pos()
enddef

def FindLastFuncHead(def_pos: list<number>): list<number>
  const func_name = GetFuncName(def_pos)
  while search('def\k*\s*\<\%(do_\)\=' .. func_name .. '\>', 'W') > 0 | endwhile

  return cursor.Pos()
enddef

def GetFuncName(def_pos: list<number>): string
  cursor.Set(def_pos)
  normal! w
  const func = matchstr(expand('<cword>'), '^\%(do_\)\=\zs\k*')
  normal! b

  return func
enddef

def FindEndPos(func_pos: list<number>, do_pos: list<number>): list<number>
  cursor.Set(func_pos)

  # If we're a block that was called with parens we're golden.
  if search('\%#' .. expand('<cword>') .. '/zs(') > 0
    var pair = searchpairpos('(', '', ')', '', () => cursor.OnStringOrComment())
    if v:operator ==# 'c'
      pair[1] -= 1
    endif

    return pair
  endif

  # The whole expression is wrapped in parens
  if search('(\%#' .. expand('<cword>'), 'b') > 0
    var pair = searchpairpos('(', '', ')', 'W', () => cursor.OnStringOrComment())
    pair[1] -= 1

    return pair
  endif

  cursor.Set(do_pos)

  const Skip = () => cursor.OnStringOrComment() || IsLambdaEnd(do_pos)

  if expand('<cWORD>') ==# 'do:'
    cursor.Set(do_pos)

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

    return [0, 0]
  else
    var pos = searchpairpos('\<do\>:\@!', '', '\<end\>', 'W', Skip)
    pos[1] += 2

    return pos
  endif
enddef

def GetEndPos(): list<number>
  while cursor.Char() =~ '}\|\]'
    normal! h
  endwhile

  return cursor.Pos()
enddef

def IsLambdaEnd(do_pos: list<number>): bool
  if expand('<cword>') ==# 'end'
    return searchpair('\<fn\>', '', '\<end\>\zs', 'Wbn', () => cursor.OnStringOrComment(), do_pos[0]) > 0
  endif

  return 0
enddef

def CheckForMeta(known_annotations: string): bool
  const word = expand('<cword>')
  const WORD = expand('<cWORD>')

  return cursor.SynstackStr() =~ 'Comment\|DocString' ||
    word =~ known_annotations ||
    WORD =~ known_annotations
enddef

# Text Object: block {{{1

def TextObj_block(inner: bool, include_meta: bool)
  var view = winsaveview()

  var origin = cursor.Pos()
  var start_pos = EMPTY
  var do_pos = EMPTY
  var end_pos = EMPTY
  var do = ''

  # First check if we are in `fn -> end`
  var fn_pos = HandleFn(origin, inner)

  if fn_pos == EMPTY3
    cursor.Set(origin)

    # Then check if we are between a function call and a `do`
    do_pos = FindDo('Wc')

    var func_pos = FindDoBlockHead(do_pos, 'Wb')

    if util.InRange(origin, func_pos, do_pos)
      end_pos = FindEndPos(func_pos, do_pos)
    else
      cursor.Set(origin)
      end_pos = EMPTY

      if expand('<cword>') =~# '\<end\>' && !cursor.OnStringOrComment()
        do_pos = searchpairpos('\<do\>:\@!\|\<fn\>', '', '\<end\>\zs', 'Wb', () => cursor.OnStringOrComment())
      else
        do_pos = FindDo('Wb')
      endif

      if do_pos == EMPTY
        winrestview(view)
        return
      endif

      func_pos = FindDoBlockHead(do_pos, 'Wb')

      end_pos = FindEndPos(func_pos, do_pos)
    endif

    if !util.InRange(origin, func_pos, end_pos)
      cursor.Set(origin)

      do_pos = FindDo('W')
      func_pos = FindDoBlockHead(do_pos, 'Wbc')
      end_pos = FindEndPos(func_pos, do_pos)
    endif

    if func_pos == EMPTY
      winrestview(view)
      return
    endif

    if inner
      start_pos = copy(do_pos)
      start_pos[1] = 1
    else
      start_pos = copy(func_pos)
    endif

    cursor.Set(do_pos)
    do = expand('<cWORD>')
  else
    [start_pos, do_pos, end_pos] = fn_pos
    do = '->'
  endif

  if !inner && include_meta
    cursor.Set(start_pos)

    normal! b
    if cursor.Char() !=# "="
      normal! w
    else
      normal! b
      if cursor.Char() =~ ')\|}\|\]'
        var close_char = cursor.Char()
        var open_char = util.GetPair(close_char)
        start_pos = searchpairpos(open_char, '', close_char, 'Wb', () => cursor.OnStringOrComment())
        normal! F%
        start_pos[1] = col('.')
      endif
    endif

    while getline(line('.') - 1) =~ '^\%(\s\+\)\?#'
      normal! k
    endwhile

    start_pos = [line('.'), 1]

    cursor.Set(do_pos)
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

  SelectObj(start_pos, end_pos)
enddef

def HandleFn(origin: list<number>, inner: bool): list<list<number>>
  var fn_pos = searchpos('\<fn\>', 'Wbc', 0, 0, () => cursor.OnStringOrComment())
  var do_pos = EMPTY
  var end_pos = EMPTY
  var do: string

  if fn_pos == EMPTY
    return EMPTY3
  else
    do_pos = searchpos('->', 'Wn', 0, 0, () => cursor.OnStringOrComment())
    do = '->'
    end_pos = searchpairpos('\<fn\>', '', '\<end\>', 'W', () => cursor.OnStringOrComment())
    end_pos[1] += 2

    if util.InRange(origin, fn_pos, end_pos)
      return [fn_pos, do_pos, end_pos]
    else
      return EMPTY3
    endif
  endif
enddef


# Text Object: def {{{1

def TextObj_def(kwd: string, inner: bool, include_annotations: bool)
  var known_annotations = '@doc\>\|@spec\>\|@tag\>\|@requirements\>\|\<attr\>\|\<slot\>'
  var user_annotations: string = get(g:, 'mixer_known_annotations', '')

  if !empty(user_annotations)
    known_annotations = join([known_annotations, user_annotations], '\|')
  endif

  const Skip = () => cursor.SynName() =~ 'String\|Comment'
  var view = winsaveview()
  var keyword = '\<\%(' .. escape(kwd, '|') .. '\)\>'
  var cursor_origin = cursor.Pos()

  # Being in the gutter of a def line is considered in range
  normal! ^
  var cursor_start = cursor.Pos()

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
    return
  endif

  if !inner && include_annotations
    def_pos = FindFirstFuncHead(def_pos)
  endif

  cursor.Set(def_pos)

  do_pos = FindDo('W')

  var first_head_has_keyword_do = expand('<cWORD>') ==# 'do:'

  cursor.Set(def_pos)

  if !inner && include_annotations
    FindLastFuncHead(def_pos)
    do_pos = FindDo('Wc')
  endif

  var start_pos = copy(def_pos)
  end_pos = FindEndPos(def_pos, do_pos)

  cursor.Set(def_pos)

  # Look for the meta
  if !inner && include_annotations
    const func_name = GetFuncName(def_pos)

    const stopline = max([1, search('\<end\>\|def\%(macro\)\?p\? \%(' .. func_name .. '\)\@!', 'Wbn', 0, 0, () => cursor.SynName() =~ 'String\|Comment\|DocString\|markdown')])

    search('^\s*$', 'Wb', stopline, 0, () => cursor.SynName() =~ 'String\|Comment\|DocString\|markdown')

    while search(known_annotations, 'Wb', stopline) > 0 | endwhile

    start_pos = cursor.Pos()
  endif

  if inner && first_head_has_keyword_do
    # Clear `do:` When switching to insert, leave a space after it otherwise do not.
    start_pos[0] = do_pos[0]
    start_pos[1] = do_pos[1] + (v:operator ==# 'c' ? 4 : 3)
  else
    start_pos[1] = 1
    [start_pos, end_pos] = AdjustBlockRegion(inner, 'do', start_pos, end_pos)
  endif

  SelectObj(start_pos, end_pos)
enddef


# Text Object: map {{{1

def TextObj_map(inner: bool)
  const Skip = () => cursor.OnStringOrComment()

  var view = winsaveview()
  var cursor_origin = cursor.Pos()
  var open_regex = '%\%([a-zA-Z.]\+\)\?{'

  var start_lnr: number
  var start_col: number

  if cursor.InGutter()
    normal! ^
  endif

  if cursor.SynstackStr() =~ 'Map\|Struct'
    [start_lnr, start_col] = searchpos(open_regex, 'Wcb', 0, 0, Skip)
  else
    [start_lnr, start_col] = searchpos(open_regex, 'Wc', 0, 0, Skip)
  endif

  if [start_lnr, start_col] == EMPTY
    winrestview(view)
    return
  endif

  normal! f{
  var [end_lnr, end_col] = searchpairpos('{', '', '}', 'W', Skip)

  if cursor.Char() ==# '}'
    searchpair(open_regex, '', '}', 'Wb', Skip)
  endif

  while cursor.SynstackStr() =~ 'Map\|Struct' && cursor_origin[0] > end_lnr
    if cursor.Char() ==# '}'
      searchpair(open_regex, '', '}', 'Wb', Skip)
    endif

    [start_lnr, start_col] = searchpos(open_regex, 'Wb', 0, 0, Skip)
    normal! f{

    if cursor.Char() ==# '{'
      [end_lnr, end_col] = searchpairpos('{', '', '}', 'W', Skip)
    else
      winrestview(view)
      return
    endif
  endwhile

  if start_lnr == 0 || end_lnr == 0
    winrestview(view)
    return
  endif

  var handle_empty_map = false

  if inner
    cursor.Set([start_lnr, start_col])
    normal f{

    var is_multiline = getline(".") =~ '{$'

    start_col = col('.')

    if is_multiline
      start_lnr += 1
      end_lnr -= 1
      end_col = len(getline(end_lnr))

      if v:operator ==# 'c'
        start_col = indent(start_lnr) + 1
      else
        start_col = 0
        end_col += 1
      endif
    else
      if start_col == end_col - 1
        handle_empty_map = true
        b:mixer_start_col = start_col
        b:mixer_operator = v:operator
      else
        start_col += 1
        end_col -= 1
      endif
    endif
  endif

  if !handle_empty_map
    setpos("'<", [0, start_lnr, start_col, 0])
    setpos("'>", [0, end_lnr, end_col, 0])

    normal! gv
  else
    winrestview(view)

    if v:operator ==# 'c'
      feedkeys("\<esc>")
    endif
    feedkeys("\<Plug>(ElixirExHandleEmptyMap)")
    if v:operator ==# 'c'
      feedkeys("i")
    endif
  endif
enddef

nnoremap <silent> <Plug>(ElixirExHandleEmptyMap)
      \ :call cursor.Set([line('.'), b:mixer_start_col + 1])<bar>
      \ :unlet b:mixer_operator<bar>
      \ :unlet b:mixer_start_col<cr>

# Text Object: sigil {{{1

def TextObj_sigil(inner: bool)
  # Skip delims
  # Manually skip ' and " because elixir.vim doesn't account for this.
  # I need to figure that out.
  const Skip = () =>  (
    cursor.SynName() =~ 'DelimEscape\|RegexEscapePunctuation' ||
    (
      cursor.Char() =~ '"\|''' && cursor.Char(line('.') - 1) ==# '\'
    )
  )

  var view = winsaveview()
  const open_delimiters = '{\|<\|\[\|(\|)\|\/\||\|"\|'''

  if cursor.SynName() !~ 'Sigil' && cursor.Char() =~ '\k'
    while cursor.Char() =~ '\k'
      normal! h

      if col('.') == 1
        winrestview(view)
        return
      endif
    endwhile

    if cursor.SynName() !~ 'Sigil'
      winrestview(view)
      return
    endif
  endif

  var [start_lnr: number, start_col: number] = EMPTY
  var [end_lnr: number, end_col: number] = EMPTY

  if cursor.SynName() =~ 'Sigil'
    [start_lnr, start_col] = searchpos('\~', 'Wcb', 0, 0, Skip)
  else
    [start_lnr, start_col] = searchpos('\~', 'Wc', 0, 0, Skip)
  endif

  var line = getline('.')[col('.') - 1 :]
  var open = matchstr(line, open_delimiters)

  const close = {
    '/': '/',
    '|': '|',
    "'": "'",
    '"': '"',
    '(': ')',
    '[': ']',
    '{': '}',
    '<': '>'
  }[open]

  if inner
    search(open, 'W', 0, 0, Skip)
    exec "normal! " .. len(open) .. "\<space>"
    [start_lnr, start_col] = cursor.Pos()
    search(escape(close, '"'), 'W', 0, 0, Skip)
    exec "normal! 1\<left>"
  else
    search(open, 'W', 0, 0, Skip)
    search(close, 'W', 0, 0, Skip)

    while getline('.')[col('.')] =~ '\k'
      normal! l
    endwhile
  endif

  [end_lnr, end_col] = cursor.Pos()

  setpos("'<", [0, start_lnr, start_col, 0])
  setpos("'>", [0, end_lnr, end_col, 0])

  normal! gv
enddef

# Text Object: comment  {{{1

def TextObj_comment(inner: bool)
  var view = winsaveview()
  var cursor_origin = cursor.Pos()

  normal $

  if !cursor.OnComment()
    winrestview(view)
    return
  endif

  var comment_type = cursor.OuterSynName()

  while cursor.OnComment() && comment_type == cursor.OuterSynName()
    if line('.') == 1
      break
    endif

    normal k$
  endwhile

  if !cursor.OnComment() || comment_type != cursor.OuterSynName()
    normal j$
  endif

  var start_lnr = line('.')
  var start_col = 0

  cursor.Set(cursor_origin)

  normal $

  while cursor.OnComment() && comment_type ==# cursor.OuterSynName()
    if line('.') == line('$')
      break
    endif

    normal j$
  endwhile

  if !cursor.OnComment() || comment_type != cursor.OuterSynName()
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

  SelectObj([start_lnr, start_col], [end_lnr, end_col])
enddef
