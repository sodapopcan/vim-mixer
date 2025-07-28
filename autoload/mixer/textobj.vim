vim9script

import autoload './cursor.vim'
import autoload './code.vim'

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

# Common {{{1

def SelectObj(start_pos: list<number>, end_pos: list<number>)
  const [start_lnr, start_col] = start_pos
  const [end_lnr, end_col] = end_pos

  setpos("'<", [0, start_lnr, start_col, 0])
  setpos("'>", [0, end_lnr, end_col, 0])

  normal! gv
enddef

# def/fn/do/end/etc Helpers {{{1

# Text Object: block {{{1

def TextObj_block(inner: bool, include_meta: bool)
  const [start_pos, end_pos] = code.GetBlock(inner, include_meta)

  if [start_pos, end_pos] != EMPTY2
    SelectObj(start_pos, end_pos)
  endif
enddef

# Text Object: def {{{1

def TextObj_def(kwd: string, inner: bool, include_annotations: bool)
  const [start_pos, end_pos] = code.GetDef(kwd, inner, include_annotations)

  if [start_pos, end_pos] != EMPTY2
    SelectObj(start_pos, end_pos)
  endif
enddef

# Text Object: comment  {{{1

def TextObj_comment(inner: bool)
  const [start_point, end_point] = code.GetComment(inner)

  if [start_pos, end_pos] != EMPTY2
    SelectObj(start_point, end_point)
  endif
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

