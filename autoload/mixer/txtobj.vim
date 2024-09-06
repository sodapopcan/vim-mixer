vim9script

import autoload './cursor'

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
    call feedkeys("\<c-r>=MixerRestoreViewInsert()\<cr>")
  else
    call feedkeys("\<Plug>(MixerRestorView)")
  endif
enddef

def MixerRestoreViewInsert()
  call winrestview(g:mixer_view)
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
  var fn_pos = HandleFn(origin, a:inner)

  if fn_pos == EMPTY3
    cursor(origin)

    " Then check if we are between a function call and a `do`
    var do_pos = FindDo('Wc')

    var func_pos = find_do_block_head(do_pos, 'Wb')
    var end_pos = [0, 0]

    if util.InRange(origin, func_pos, do_pos)
      end_pos = syntax.FindEndPos(func_pos, do_pos)
    else
      call cursor(origin)
      let end_pos = s:empty

      if expand('<cword>') =~# '\<end\>' && !s:is_string_or_comment()
        let do_pos = searchpairpos('\<do\>:\@!\|\<fn\>', '', '\<end\>\zs', 'Wb', {-> s:is_string_or_comment()})
      else
        let do_pos = s:find_do('Wb')
      endif

      if do_pos == s:empty
        return winrestview(view)
      endif

      let func_pos = s:find_do_block_head(do_pos, 'Wb')

      let end_pos = s:find_end_pos(func_pos, do_pos)
    endif

    if !s:in_range(origin, func_pos, end_pos)
      call cursor(origin)

      let do_pos = s:find_do('W')
      let func_pos = s:find_do_block_head(do_pos, 'Wbc')
      let end_pos = s:find_end_pos(func_pos, do_pos)
    endif

    if func_pos == s:empty | return winrestview(view) | endif

    if a:inner
      let start_pos = copy(do_pos)
      let start_pos[1] = 1
    else
      let start_pos = copy(func_pos)
    endif

    call cursor(do_pos)
    let do = expand('<cWORD>')
  else
    let [start_pos, do_pos, end_pos] = fn_pos
    let do = '->'
  endif

  if !a:inner && a:include_meta
    call cursor(start_pos)

    normal! b
    if s:cursor_char() !=# "="
      normal! w
    else
      normal! b
      if s:cursor_char() =~ ')\}\|\|\]'
        let close_char = s:cursor_char()
        let open_char = s:get_pair(close_char)
        let start_pos = searchpairpos(open_char, '', close_char, 'Wb', {-> s:is_string_or_comment()})
        normal! F%
        let start_pos[1] = col('.')
      endif
    endif

    while getline(line('.') - 1) =~ '^\%(\s\+\)\?#'
      normal! k
    endwhile

    let start_pos = [line('.'), 1]

    call cursor(do_pos)
  endif

  if a:inner && do =~# 'do:\|->'
    if do ==# 'do:'
      let start_pos[0] = do_pos[0]
      " Clear `do:` When switching to insert, leaving a space after it.
      let start_pos[1] = do_pos[1] + (v:operator ==# 'c' ? 4 : 3)
    elseif do ==# '->'
      " Clear `->` When switching to insert, leaving a space after it.
      let start_pos[1] = do_pos[1] + (v:operator ==# 'c' ? 3 : 2)
      let [start_pos, end_pos] = s:adjust_block_region(a:inner, do, start_pos, end_pos)
    endif
  else
    let [start_pos, end_pos] = s:adjust_block_region(a:inner, do, start_pos, end_pos)
  endif

  let view.lnum = start_pos[0]
  if a:inner
    let view.col = start_pos[1]
  endif

  call s:textobj_select_obj(view, start_pos, end_pos)
endfunction

function! s:handle_fn(origin, inner)
  let fn_pos = searchpos('\<fn\>', 'Wbc', 0, 0, {-> s:is_string_or_comment()})

  if fn_pos == s:empty
    return s:empty3
  else
    let do_pos = searchpos('->', 'Wn', 0, 0, {-> s:is_string_or_comment()})
    let do = '->'
    let end_pos = searchpairpos('\<fn\>', '', '\<end\>', 'W', {-> s:is_string_or_comment()})
    let end_pos[1] += 2

    if s:in_range(a:origin, fn_pos, end_pos)
      return [fn_pos, do_pos, end_pos]
    else
      return s:empty3
    endif
  endif
endfunction


" Text Objects: def {{{1

function! s:textobj_def(keyword, inner, include_annotations) abort
  let known_annotations = '@doc\>\|@spec\>\|@tag\>\|@requirements\>\|\<attr\>\|\<slot\>'
  let user_annotations = get(g:, 'mixer_known_annotations', 0)

  if user_annotations != 0
    let known_annotations = join([known_annotations, user_annotations], '\|')
  endif

  let Skip = {-> s:cursor_syn_name() =~ 'String\|Comment'}
  let view = winsaveview()
  let keyword = '\<\%('.escape(a:keyword, '|').'\)\>'
  let cursor_origin = s:get_cursor_pos()

  " Being in the gutter of a def line is considered in range
  normal! ^
  let cursor_start = s:get_cursor_pos()

  if s:check_for_meta(known_annotations)
    call search(keyword, 'W', 0, 0, Skip)
  endif

  " Search backward
  let def_pos = searchpos(keyword, 'Wcb', 0, 0, Skip)
  let do_pos = s:find_do('W')
  let end_pos = s:find_end_pos(def_pos, do_pos)

  if !s:in_range(cursor_start, def_pos, end_pos) || do_pos == s:empty
    call winrestview(view)

    let def_pos = searchpos(keyword, 'W', 0, 0, Skip)
  endif

  if def_pos == s:empty | return winrestview(view) | endif

  if !a:inner && a:include_annotations
    let def_pos = s:find_first_func_head(def_pos)
  endif

  call cursor(def_pos)

  let do_pos = s:find_do('W')

  let first_head_has_keyword_do = expand('<cWORD>') ==# 'do:'

  call cursor(def_pos)

  if !a:inner && a:include_annotations
    call s:find_last_func_head(def_pos)
    let do_pos = s:find_do('Wc')
  endif

  let start_pos = copy(def_pos)
  let end_pos = s:find_end_pos(def_pos, do_pos)

  call cursor(def_pos)

  " Look for the meta
  if !a:inner && a:include_annotations
    let func_name = s:get_func_name(def_pos)

    let stopline = max([1, search('\<end\>\|def\%(macro\)\?p\? \%('.func_name.'\)\@!', 'Wbn', 0, 0, {-> s:cursor_syn_name() =~ 'String\|Comment\|DocString\|markdown'})])

    call search('^\s*$', 'Wb', stopline, 0, {-> s:cursor_syn_name() =~ 'String\|Comment\|DocString\|markdown'})

    while search(known_annotations, 'Wb', stopline) | endwhile

    let start_pos = s:get_cursor_pos()
  endif

  if a:inner && first_head_has_keyword_do
    " Clear `do:` When switching to insert, leave a space after it otherwise do not.
    let start_pos[0] = do_pos[0]
    let start_pos[1] = do_pos[1] + (v:operator ==# 'c' ? 4 : 3)
  else
    let start_pos[1] = 1
    let [start_pos, end_pos] = s:adjust_block_region(a:inner, 'do', start_pos, end_pos)
  endif

  let view.lnum = start_pos[0]
  let view.col = start_pos[1]
  call s:textobj_select_obj(view, start_pos, end_pos)
endfunction


" Text Objects: map {{{1

function! s:textobj_map(inner) abort
  let Skip = {-> s:is_string_or_comment()}

  let view = winsaveview()
  let cursor_origin = s:get_cursor_pos()
  let open_regex = '%\%([a-zA-Z.]\+\)\?{'

  if s:cursor_in_gutter()
    normal! ^
  endif

  if s:cursor_synstack_str() =~ 'Map\|Struct'
    let [start_lnr, start_col] = searchpos(open_regex, 'Wcb', 0, 0, Skip)
  else
    let [start_lnr, start_col] = searchpos(open_regex, 'Wc', 0, 0, Skip)
  endif

  if [start_lnr, start_col] == s:empty
    return winrestview(view)
  endif

  normal! f{
  let [end_lnr, end_col] = searchpairpos('{', '', '}', 'W', Skip)

  if s:cursor_char() ==# '}'
    call searchpair(open_regex, '', '}', 'Wb', Skip)
  endif

  while s:cursor_synstack_str() =~ 'Map\|Struct' && cursor_origin[0] > end_lnr
    if s:cursor_char() ==# '}'
      call searchpair(open_regex, '', '}', 'Wb', Skip)
    endif

    let [start_lnr, start_col] = searchpos(open_regex, 'Wb', 0, 0, Skip)
    normal! f{

    if s:cursor_char() ==# '{'
      let [end_lnr, end_col] = searchpairpos('{', '', '}', 'W', Skip)
    else
      return winrestview(view)
    end
  endwhile

  if start_lnr == 0 || end_lnr == 0
    return winrestview(view)
  endif

  let handle_empty_map = 0

  if a:inner
    call cursor(start_lnr, start_col)
    normal f{

    let is_multiline = getline(".") =~ '{$'

    let start_col = col('.')

    if is_multiline
      let start_lnr += 1
      let end_lnr -= 1
      let end_col = len(getline(end_lnr))

      if v:operator ==# 'c'
        let start_col = indent(start_lnr) + 1
      else
        let start_col = 0
        let end_col += 1
      endif
    else
      if start_col == end_col - 1
        let handle_empty_map = 1
        let b:mixer_start_col = start_col
        let b:mixer_operator = v:operator
      else
        let start_col += 1
        let end_col -= 1
      endif
    endif
  endif

  if !handle_empty_map
    call setpos("'<", [0, start_lnr, start_col, 0])
    call setpos("'>", [0, end_lnr, end_col, 0])

    normal! gv
  else
    call winrestview(view)

    if v:operator ==# 'c'
      call feedkeys("\<esc>")
    endif
    call feedkeys("\<Plug>(ElixirExHandleEmptyMap)")
    if v:operator ==# 'c'
      call feedkeys("i")
    endif
  endif
endfunction

nnoremap <silent> <Plug>(ElixirExHandleEmptyMap)
      \ :call cursor([line('.'), b:mixer_start_col + 1])<bar>
      \ :unlet b:mixer_operator<bar>
      \ :unlet b:mixer_start_col<cr>

" Text Objects: sigil {{{1

function! s:textobj_sigil(inner)
  " Skip delims
  " Manually skip ' and " because elixir.vim doesn't account for this.
  " I need to figure that out.
  let Skip = { -> 
        \   s:cursor_syn_name() =~ 'DelimEscape\|RegexEscapePunctuation' ||
        \   (
        \     s:cursor_char() =~ '"\|''' && s:cursor_char(line('.') - 1) ==# '\'
        \   )
        \ }

  let view = winsaveview()
  let open_delimiters = '{\|<\|\[\|(\|)\|\/\||\|"\|'''

  if s:cursor_syn_name() !~ 'Sigil' && s:cursor_char() =~ '\k'
    while s:cursor_char() =~ '\k'
      normal! h

      if col('.') == 1
        return winrestview(view)
      endif
    endwhile

    if s:cursor_syn_name() !~ 'Sigil'
      return winrestview(view)
    endif
  endif

  if s:cursor_syn_name() =~ 'Sigil'
    let [start_lnr, start_col] = searchpos('\~', 'Wcb', 0, 0, Skip)
  else
    let [start_lnr, start_col] = searchpos('\~', 'Wc', 0, 0, Skip)
  endif

  let line = getline('.')[col('.') - 1:]
  let open = matchstr(line, open_delimiters)

  let close = {
        \   '/': '/',
        \   '|': '|',
        \   "'": "'",
        \   '"': '"',
        \   '(': ')',
        \   '[': ']',
        \   '{': '}',
        \   '<': '>'
        \ }[open]

  if a:inner
    call search(open, 'W', 0, 0, Skip)
    exec "normal! ".len(open)."\<space>"
    let [start_lnr, start_col] = s:get_cursor_pos()
    call search(escape(close, '"'), 'W', 0, 0, Skip)
    exec "normal! 1\<left>"
  else
    call search(open, 'W', 0, 0, Skip)
    call search(close, 'W', 0, 0, Skip)

    while getline('.')[col('.')] =~ '\k'
      normal! l
    endwhile
  endif

  let [end_lnr, end_col] = s:get_cursor_pos()

  call setpos("'<", [0, start_lnr, start_col, 0])
  call setpos("'>", [0, end_lnr, end_col, 0])

  normal! gv
endfunction

" Text Objects: comment  {{{1

function! s:textobj_comment(inner)
  let view = winsaveview()
  let cursor_origin = getcurpos('.')

  normal $

  if !s:cursor_on_comment()
    return winrestview(view)
  endif

  let comment_type = s:cursor_outer_syn_name()

  while s:cursor_on_comment() && comment_type == s:cursor_outer_syn_name()
    if line('.') == 1
      break
    endif

    normal k$
  endwhile

  if !s:cursor_on_comment() || comment_type != s:cursor_outer_syn_name()
    normal j$
  endif

  let start_lnr = line('.')
  let start_col = 0

  call setpos('.', cursor_origin)

  normal $

  while s:cursor_on_comment() && comment_type ==# s:cursor_outer_syn_name()
    if line('.') == line('$')
      break
    endif

    normal j$
  endwhile

  if !s:cursor_on_comment() || comment_type != s:cursor_outer_syn_name()
    normal k$
  endif

  let end_lnr = line('.')

  if a:inner && comment_type ==# 'DocString'
    let start_lnr += 1
    let end_lnr -= 1
    let end_col = len(getline(end_lnr))
  else
    let end_col = len(getline(end_lnr)) + 1
  endif

  let view.lnum = start_lnr
  call s:textobj_select_obj(view, [start_lnr, start_col], [end_lnr, end_col])
endfunction
