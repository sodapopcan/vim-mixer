vim9script

import autoload './cursor'
import autoload './textobj_syntax.vim' as syntax

const EMPTY = [0, 0]
const EMPTY2 = [[0, 0], [0, 0]]
const EMPTY3 = [[0, 0], [0, 0], [0, 0]]

def TextobjSelectObj(view: dict<any>, start_pos: list<number>, end_pos: list<number>): void
  const [start_lnr, start_col] = start_pos
  const [end_lnr, end_col] = end_pos

  g:mixer_view = view

  if v:operator ==# 'c'
    unlet g:mixer_view.lnum
    unlet g:mixer_view.col
  endif

  setpos("'<", [0, start_lnr, start_col, 0])
  setpos("'>", [0, end_lnr, end_col, 0])

  normal! gv

  if v:operator ==# 'c'
    feedkeys("\<c-r>=g:MixerRestoreViewInsert()\<cr>")
  else
    feedkeys("\<Plug>(MixerRestorView)")
  endif
enddef

def g:MixerRestoreViewInsert()
  winrestview(g:mixer_view)
  unlet g:mixer_view

  return ""
enddef

nnoremap <silent> <Plug>(MixerRestorView)
      \ :call winrestview(g:mixer_view)<bar>
      \ :unlet g:mixer_view<cr>

def AdjustWhitespace(start_pos: list<number>): list<number>
  var [start_lnr, start_col] = start_pos

  var start_line = getline(start_lnr)
  var prev_blank = util.IsBlank(getline(start_lnr - 1))
  var offset = 0

  if start_col > 2
    offset = start_col - 2
  else
    var offset = 0
  endif
  const empty_gutter = start_line[0 : offset] =~ '^\s*$'

  if start_lnr > 1 && prev_blank && empty_gutter
    start_lnr -= 1
    start_col = 1
  elseif start_lnr > 1 && empty_gutter
    start_col = 1
  endif

  return [start_lnr, start_col]
endfunction

def AdjustBlockRegion(inner: bool, do: string, start_pos: number, end_pos: number): list<list<number>>
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
      exec start_lnr + 1
      if do !=# '->'
        start_col = indent(start_lnr) + 1
        end_col = len(getline(end_lnr))
      endif
    else
      if do !=# '->'
        end_col = len(getline(end_lnr)) + 1 # Include \n
      endif
      exec start_lnr
    endif
  else
    [start_lnr, start_col] = AdjustWhitespace([start_lnr, start_col])

    if start_col == 0
      start_col = 1
    endif

    if do ==# 'do'
      end_col = len(getline(end_lnr)) + 1 # Include \n
    endif

    exec start_lnr
  endif

  return [[start_lnr, start_col], [end_lnr, end_col]]
enddef


# Text Objects: block {{{1

def TextobjBlock(inner: bool, include_meta: bool): void
  var view = winsaveview()

  var origin = cursor.Pos()
  # First check if we are in `fn -> end`
  var fn_pos = HandleFn(origin, inner)

  if fn_pos == EMPTY3
    cursor(origin)

    # Then check if we are between a function call and a `do`
    var do_pos = syntax.FindDo('Wc')

    var func_pos = find_do_block_head(do_pos, 'Wb')
    var end_pos = [0, 0]

    if util.InRange(origin, func_pos, do_pos)
      end_pos = syntax.FindEndPos(func_pos, do_pos)
    else
      cursor(origin)
      var end_pos = EMPTY

      if expand('<cword>') =~# '\<end\>' && !cursor.OnStringOrComment()
        do_pos = searchpairpos('\<do\>:\@!\|\<fn\>', '', '\<end\>\zs', 'Wb', () => cursor.OnStringOrComment())
      else
        do_pos = FindDo('Wb')
      endif

      if do_pos == EMPTY
        return winrestview(view)
      endif

      func_pos = syntax.FindDoBlockHead(do_pos, 'Wb')

      end_pos = syntax.FindEndPos(func_pos, do_pos)
    endif

    if !util.InRange(origin, func_pos, end_pos)
      cursor(origin)

      do_pos = syntax.FindDo('W')
      func_pos = syntax.FindDoBlockHead(do_pos, 'Wbc')
      end_pos = syntax.FindEndPos(func_pos, do_pos)
    endif

    if func_pos == EMPTY
      return winrestview(view)
    endif

    if inner
      start_pos = copy(do_pos)
      start_pos[1] = 1
    else
      start_pos = copy(func_pos)
    endif

    cursor(do_pos)
    do = expand('<cWORD>')
  else
    [start_pos, do_pos, end_pos] = fn_pos
    do = '->'
  endif

  if !inner && include_meta
    cursor(start_pos)

    normal! b
    if cursor_char() !=# "="
      normal! w
    else
      normal! b
      if cursor_char() =~ ')\}\|\|\]'
        close_char = cursor_char()
        open_char = syntax.GetPair(close_char)
        start_pos = searchpairpos(open_char, '', close_char, 'Wb', () => cursor.OnStringOrComment())
        normal! F%
        start_pos[1] = col('.')
      endif
    endif

    while getline(line('.') - 1) =~ '^\%(\s\+\)\?#'
      normal! k
    endwhile

    start_pos = [line('.'), 1]

    cursor(do_pos)
  endif

  if inner && do =~# 'do:\|->'
    if do ==# 'do:'
      start_pos[0] = do_pos[0]
      # Clear `do:` When switching to insert, leaving a space after it.
      start_pos[1] = do_pos[1] + (v:operator ==# 'c' ? 4 : 3)
    elseif do ==# '->'
      # Clear `->` When switching to insert, leaving a space after it.
      start_pos[1] = do_pos[1] + (v:operator ==# 'c' ? 3 : 2)
      [start_pos, end_pos] = syntax.AdjustBlockRegion(inner, do, start_pos, end_pos)
    endif
  else
    [start_pos, end_pos] = syntax.AdjustBlockRegion(inner, do, start_pos, end_pos)
  endif

  view.lnum = start_pos[0]
  if inner
    view.col = start_pos[1]
  endif

  TextobjSelectObj(view, start_pos, end_pos)
endfunction

def HandleFn(origin: list<number>, inner: bool): list<number>
  var fn_pos = searchpos('\<fn\>', 'Wbc', 0, 0, () => cursor.OnStringOrComment())
  var do_pos = EMPTY
  var end_pos = EMPTY

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
endfunction


# Text Objects: def {{{1

def TextobjDef(keyword: string, inner: bool, include_annotations: bool): void
  var known_annotations = '@doc\>\|@spec\>\|@tag\>\|@requirements\>\|\<attr\>\|\<slot\>'
  var user_annotations: string = get(g:, 'mixer_known_annotations', '')

  if !empty(user_annotations)
    known_annotations = join([known_annotations, user_annotations], '\|')
  endif

  const Skip = () => cursor.SynName() =~ 'String\|Comment'
  var view = winsaveview()
  var keyword = '\<\%('.escape(keyword, '|').'\)\>'
  var cursor_origin = cursor.Pos()

  # Being in the gutter of a def line is considered in range
  normal! ^
  var cursor_start = cursor.Pos()

  if syntax.CheckForMeta(known_annotations)
    search(keyword, 'W', 0, 0, Skip)
  endif

  # Search backward
  var def_pos = searchpos(keyword, 'Wcb', 0, 0, Skip)
  var do_pos = syntax.FindDo('W')
  var end_pos = syntax.FindEndPos(def_pos, do_pos)

  if !util.InRange(cursor_start, def_pos, end_pos) || do_pos == EMPTY
    winrestview(view)

    def_pos = searchpos(keyword, 'W', 0, 0, Skip)
  endif

  if def_pos == EMPTY | return winrestview(view) | endif

  if !inner && include_annotations
    def_pos = syntax.FindFirstFuncHead(def_pos)
  endif

  cursor(def_pos)

  do_pos = syntax.FindDo('W')

  var first_head_has_keyword_do = expand('<cWORD>') ==# 'do:'

  cursor(def_pos)

  if !inner && include_annotations
    syntax.find_last_func_head(def_pos)
    do_pos = syntax.FindDo('Wc')
  endif

  start_pos = copy(def_pos)
  end_pos = syntax.FindEndPos(def_pos, do_pos)

  cursor(def_pos)

  # Look for the meta
  if !inner && include_annotations
    const func_name = syntax.GetFuncName(def_pos)

    const stopline = max([1, search('\<end\>\|def\%(macro\)\?p\? \%('.func_name.'\)\@!', 'Wbn', 0, 0, () => cursor.SynName() =~ 'String\|Comment\|DocString\|markdown')])

    search('^\s*$', 'Wb', stopline, 0, () -> cursor.SynName() =~ 'String\|Comment\|DocString\|markdown')

    while search(known_annotations, 'Wb', stopline) | endwhile

    start_pos = cursor.Pos()
  endif

  if inner && first_head_has_keyword_do
    " Clear `do:` When switching to insert, leave a space after it otherwise do not.
    start_pos[0] = do_pos[0]
    start_pos[1] = do_pos[1] + (v:operator ==# 'c' ? 4 : 3)
  else
    start_pos[1] = 1
    [start_pos, end_pos] = AdjustBlockRegion(inner, 'do', start_pos, end_pos)
  endif

  view.lnum = start_pos[0]
  view.col = start_pos[1]
  TextobjSelectObj(view, start_pos, end_pos)
enddef


# Text Objects: map {{{1

def TextobjMap(inner: bool): void
  const Skip = () => cursor.OnStringOrComment()

  var view = winsaveview()
  var cursor_origin = s:get_cursor_pos()
  var open_regex = '%\%([a-zA-Z.]\+\)\?{'

  if cursor.InGutter()
    normal! ^
  endif

  var [start_lnr, start_col] = EMPTY2

  if cursor.SynstackStr() =~ 'Map\|Struct'
    [start_lnr, start_col] = searchpos(open_regex, 'Wcb', 0, 0, Skip)
  else
    [start_lnr, start_col] = searchpos(open_regex, 'Wc', 0, 0, Skip)
  endif

  if [start_lnr, start_col] == EMPTY
    return winrestview(view)
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
      return winrestview(view)
    endif
  endwhile

  if start_lnr == 0 || end_lnr == 0
    return winrestview(view)
  endif

  var handle_empty_map = false

  if inner
    cursor(start_lnr, start_col)
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
      \ :call cursor([line('.'), b:mixer_start_col + 1])<bar>
      \ :unlet b:mixer_operator<bar>
      \ :unlet b:mixer_start_col<cr>

# Text Objects: sigil {{{1

def TextobjSigil(inner: bool): void
  # Skip delims
  # Manually skip ' and " because elixir.vim doesn't account for this.
  # I need to figure that out.
  const Skip = { -> 
  cursor.SynName() =~ 'DelimEscape\|RegexEscapePunctuation' ||
    (
      cursor.Char() =~ '"\|''' && cursor.Char(line('.') - 1) ==# '\'
    )
  }

  var view = winsaveview()
  const open_delimiters = '{\|<\|\[\|(\|)\|\/\||\|"\|'''

  if cursor.SynName() !~ 'Sigil' && cursor.Char() =~ '\k'
    while cursor.Char() =~ '\k'
      normal! h

      if col('.') == 1
        return winrestview(view)
      endif
    endwhile

    if cursor.SynName() !~ 'Sigil'
      return winrestview(view)
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
    exec "normal! ".len(open)."\<space>"
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

# Text Objects: comment  {{{1

def TextobjComment(inner: bool): void
  var view = winsaveview()
  var cursor_origin = getcurpos('.')

  normal $

  if !cursor.OnComment()
    return winrestview(view)
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

  setpos('.', cursor_origin)

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

  end_lnr = line('.')

  if inner && comment_type ==# 'DocString'
    start_lnr += 1
    end_lnr -= 1
    end_col = len(getline(end_lnr))
  else
    end_col = len(getline(end_lnr)) + 1
  endif

  view.lnum = start_lnr
  TextobjSelectObj(view, [start_lnr, start_col], [end_lnr, end_col])
enddef
