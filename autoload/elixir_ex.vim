" Location:     autoload/elixir_ex.vim
" Maintainer:   Andrew Haust <https://andrew.hau.st>

" Utility {{{1

function! s:sub(str, pat, rep)
  return substitute(a:str, a:pat, a:rep, '')
endfunction

function! s:matches(str, pat)
  return match(str, path) >= 0
endfunction

function! s:is_blank(str)
  return empty(trim(a:str))
endfunction

" Check if cursor is in range of two positions.
" Positions are in the form of [line, col].
function! s:in_range(lnr, col, start, end) abort
  let [start_lnr, start_col] = a:start
  let [end_lnr, end_col] = a:end

  if a:lnr > start_lnr && a:lnr < end_lnr
    return 1
  endif

  if a:lnr == start_lnr && a:lnr == end_lnr
    return a:col >= start_col && a:col <= end_col
  endif

  if a:lnr == start_lnr && a:col >= start_col
    return 1
  endif

  if a:lnr == end_lnr && a:col <= end_col
    return 1
  endif

  return 0
endfunction

function! s:command_exists(cmd)
  return exists(":".a:cmd) == 2
endfunction

" Init {{{1

function! elixir_ex#init() abort
  let defregex = 'def\|defp\|defmacro\|defmacrop\|defprotocol\|defimpl'
  let macros = [[defregex, 'f'], ['defmodule', 'M'], ['quote', 'q']]

  for [macro, obj] in macros
    exec "vnoremap <silent> <buffer> i".obj." :\<c-u>call <sid>textobj_def('".macro."', 1, 0)\<cr>"
    exec "vnoremap <silent> <buffer> a".obj." :\<c-u>call <sid>textobj_def('".macro."', 0, 0)\<cr>"
    exec "onoremap <silent> <buffer> i".obj." :call <sid>textobj_def('".macro."', 1, 0)\<cr>"
    exec "onoremap <silent> <buffer> a".obj." :call <sid>textobj_def('".macro."', 0, 0)\<cr>"
  endfor

  exec "vnoremap <silent> <buffer> iF :\<c-u>call <sid>textobj_def('".defregex."', 1, 1)\<cr>"
  exec "vnoremap <silent> <buffer> aF :\<c-u>call <sid>textobj_def('".defregex."', 0, 1)\<cr>"
  exec "onoremap <silent> <buffer> iF :call <sid>textobj_def('".defregex."', 1, 1)\<cr>"
  exec "onoremap <silent> <buffer> aF :call <sid>textobj_def('".defregex."', 0, 1)\<cr>"

  vnoremap <silent> <buffer> iq :\<c-u>call <sid>textobj_def('quote', 1, 1)\<cr>
  vnoremap <silent> <buffer> aq :\<c-u>call <sid>textobj_def('quote', 0, 1)\<cr>
  onoremap <silent> <buffer> iq :call <sid>textobj_def('quote', 1, 1)\<cr>
  onoremap <silent> <buffer> aq :call <sid>textobj_def('quote', 0, 1)\<cr>

  vnoremap <silent> <buffer> id :<c-u>call <sid>textobj_block(1)<cr>
  vnoremap <silent> <buffer> ad :<c-u>call <sid>textobj_block(0)<cr>
  onoremap <silent> <buffer> id :call <sid>textobj_block(1)<cr>
  onoremap <silent> <buffer> ad :call <sid>textobj_block(0)<cr>

  vnoremap <silent> <buffer> ic :<c-u>call <sid>textobj_comment(1)<cr>
  vnoremap <silent> <buffer> ac :<c-u>call <sid>textobj_comment(0)<cr>
  onoremap <silent> <buffer> ic :call <sid>textobj_comment(1)<cr>
  onoremap <silent> <buffer> ac :call <sid>textobj_comment(0)<cr>

  vnoremap <silent> <buffer> im :<c-u>call <sid>textobj_map(1)<cr>
  vnoremap <silent> <buffer> am :<c-u>call <sid>textobj_map(0)<cr>
  onoremap <silent> <buffer> im :call <sid>textobj_map(1)<cr>
  onoremap <silent> <buffer> am :call <sid>textobj_map(0)<cr>

  if !s:command_exists("ToPipe")
    command -buffer -nargs=0 ToPipe call s:to_pipe()
  endif

  if !s:command_exists("FromPipe")
    command -buffer -nargs=0 FromPipe call s:from_pipe()
  endif
endfunction


" Syntax Helpers {{{1

function! s:cursor_char(...)
  if a:0
    return getline('.')[a:1 - 1]
  else
    return getline('.')[col('.') - 1]
  endif
endfunction

function! s:cursor_prev_char()
  return getline('.')[col('.') - 2]
endfunction

function! s:cursor_term()
  return s:sub((synIDattr(synID(line('.'), col('.'), 1), "name")), '^elixir', '')
endfunction

function! s:cursor_in_gutter()
  let leading_whitespace_len = len(matchstr(getline('.'), '^\s\+'))

  return col('.') <= leading_whitespace_len
endfunction

" Move the cursor one character forward across newlines
function! s:cursor_move_forward()
  exec "normal! 1\<space>"
endfunction

function! s:cursor_move_back()
  exec "normal! 1\<bs>"
endfunction

function! s:cursor_outer_syn_name()
  let terms = map(synstack(line('.'), col('.')), 'synIDattr(v:val,"name")')
  let terms = filter(terms, 'v:val !=# "elixirBlock"')

  if empty(terms) | return '' | endif

  return s:sub(s:sub(terms[0], 'elixir', ''), 'Delimiter', '')
endfunction

function! s:cursor_synstack_str()
  let terms = map(synstack(line('.'), col('.')), 'synIDattr(v:val,"name")')
  let terms = filter(terms, 'v:val !=# "elixirBlock"')

  return join(terms, ',')
endfunction

function! s:is_lambda()
  let terms = map(synstack(line('.'), col('.')), 'synIDattr(v:val,"name")')
  let terms = filter(terms, 'v:val =~ "Lambda"')

  if empty(terms) | return '' | endif

  return terms[0] ==# 'elixirLambda'
endfunction

function! s:cursor_function_metadata()
  return index(['Comment', 'DocString', 'DocStringDelimiter', 'Variable'], s:cursor_outer_syn_name()) > -1
endfunction

function! s:cursor_on_comment()
  return index(['Comment', 'DocString', 'DocStringDelimiter'], s:cursor_outer_syn_name()) > -1
endfunction

function! s:cursor_on_comment_or_blank_line()
  return s:cursor_on_comment() || s:is_blank(getline('.'))
endfunction

function! s:is_string_or_comment()
  return s:cursor_term() =~ '\%(String\|Comment\|CharList\|Atom\)'
endfunction

function! s:starts_with_pipe(line)
  return match(trim(a:line), '^|>') >= 0
endfunction

function! s:empty_parens()
  let cursor = getpos(".")
  let save_i = @i
  normal! "iyib
  let is_empty = s:is_blank(@i)
  let @i = save_i
  call setpos(".", cursor)

  return is_empty
endfunction

function! s:get_term(cmd)
  let save_i = @i
  exec 'normal! "i'.a:cmd
  let value = @i
  let @i = save_i

  return value
endfunction

function! s:get_outer_term()
  let outer_term = s:cursor_outer_syn_name()

  if outer_term ==# 'Map'
    let value = s:get_term('da{')

    if getline('.')[col('.') - 1] == "%"
      normal! x
    else
      normal! X
    endif

    return "%".value
  elseif outer_term ==# 'List'
    return s:get_term('da[')
  elseif outer_term ==# 'String'
    return s:get_term('ida"')
  elseif outer_term ==# 'Tuple'
    return s:get_term('da{')
  elseif outer_term ==# 'CharList'
    return s:get_term("da'")
    " elseif outer_term ==# 'Sigil'
    "   normal! F~
    "\~\%([a-z]\|[A-Z]\+\)\%([\[{('"|/<]\).*\%([\]})'"|/>]\)"
  else
    return s:get_term("daW")
  endif
endfunction

" Text Objects {{{1

" -- helpers {{{1
function! s:textobj_select_obj(view, start_lnr, start_col, end_lnr, end_col)
  let g:elixir_ex_view = a:view

  if v:operator ==# 'c'
    unlet g:elixir_ex_view.lnum
    unlet g:elixir_ex_view.col
  endif

  call setpos("'<", [0, a:start_lnr, a:start_col, 0])
  call setpos("'>", [0, a:end_lnr, a:end_col, 0])

  normal! gv

  if v:operator ==# 'c'
    call feedkeys("\<c-o>\<Plug>(ElixirExRestoreView)\<right>")
  else
    call feedkeys("\<Plug>(ElixirExRestoreView)")
  endif
endfunction!

nnoremap <silent> <Plug>(ElixirExRestoreView)
      \ :call winrestview(g:elixir_ex_view)<bar>
      \ :unlet g:elixir_ex_view<bar>
      \ :normal! ^<cr>

" -- textobj_map {{{1

function! s:textobj_map(inside) abort
  let Skip = {-> s:is_string_or_comment()}

  let view = winsaveview()
  let cursor_origin = [line('.'), col('.')]
  let open_regex = '%\%([a-zA-Z.]\+\)\?{'

  if s:cursor_in_gutter()
    normal! ^
  endif

  if s:cursor_synstack_str() =~ 'Map\|Struct'
    let [start_lnr, start_col] = searchpos(open_regex, 'Wcb', 0, 0, Skip)
  else
    let [start_lnr, start_col] = searchpos(open_regex, 'Wc', 0, 0, Skip)
  endif

  if [start_lnr, start_col] == [0, 0]
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

  if a:inside
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
        let b:elixir_ex_start_col = start_col
        let b:elixir_ex_operator = v:operator
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
      \ :call cursor([line('.'), b:elixir_ex_start_col + 1])<bar>
      \ :unlet b:elixir_ex_operator<bar>
      \ :unlet b:elixir_ex_start_col<cr>

" -- textobj_block {{{1

function! s:textobj_block(inside) abort
  let Skip = {-> s:skip_terms(["Tuple", "String", "Comment"]) || s:is_lambda()}
  let view = winsaveview()

  normal! ^

  let [cursor_origin_lnr, cursor_origin_col] = [line('.'), col('.')]
  let do_pos = searchpos('\<do\>', 'Wc', 0, 0, Skip)
  let func_pos = s:jump_to_function()

  if s:in_range(cursor_origin_lnr, cursor_origin_col, func_pos, do_pos)
    call setpos('.', [0, do_pos[0], do_pos[1], 0])
    let [end_lnr, end_col] = searchpairpos('\<do\>', '', '\<end\>', 'Wn', Skip)
  else
    call winrestview(view)
    normal! wb

    let do_pos = searchpos('\<do\>', 'Wcb', 0, 0, Skip)
    let func_pos = s:jump_to_function()
    call setpos('.', [0, do_pos[0], do_pos[1], 0])
    let [end_lnr, end_col] = searchpairpos('\<do\>', '', '\<end\>', 'Wn', Skip)
  endif

  let start_col = 1

  if a:inside
    let start_lnr = do_pos[0] + 1
    let end_lnr -= 1

    if v:operator ==# 'c'
      let start_col = indent(start_lnr) + 1
      exec start_lnr + 1
      let end_col = len(getline(end_lnr))
    else
      let end_col = len(getline(end_lnr)) + 1 " Include \n
      exec start_lnr
    endif
  else
    let [start_lnr, start_col] = func_pos

    if s:is_blank(getline(start_lnr - 1))
      let start_lnr -=1
      let start_col = 1
    endif

    let end_col = len(getline(end_lnr)) + 1

    exec start_lnr
  endif

  let view.lnum = start_lnr

  call s:textobj_select_obj(view, start_lnr, start_col, end_lnr, end_col)
endfunction

function! s:jump_to_function()
  let Skip = {-> s:cursor_outer_syn_name() =~ '\%(Map\|List\|String\|Comment\|Atom\|Variable\)'}

  " With out cursor on the 'd' of a `do` block, we want to find its matching
  " function without knowing its name.

  " First lets check if we have a builtin as that is simple.
  if searchpair('\<\%(defmodule\|def\|defp\|defmacro\|defmacrop\|defprotocol\|defimpl\|case\|cond\|if\|unless\|for\|with\|test\|description\)\>', '', '\<do\>', 'Wb', {-> s:is_string_or_comment()})
  " We're not going to do anything here
  "
  " If not we're going to check if we have either a paren block or a single
  " argument list, tuple, or map.  This is the only other case like we will
  " cover for now.
  elseif search('^\%(\s\+\)\?\zs\%()\|]\|}\) \<do\>', 'Wb', line('.'))
    " We're multiline which means we can skip right to the line that has our
    " function call!  Again, this is thanks to Elixir's syntax rules that you
    " cannot have whitespace between a function call and its opening paren.
    let close_char = s:cursor_char()

    if close_char == ')'
      let open_char = '('
    elseif close_char == ']' 
      let open_char = '['
    elseif close_char == '}' 
      let open_char = '{'
    else
      return [0, 0]
    endif
    call searchpair(open_char, '', close_char, 'Wb', {-> s:is_string_or_comment()})
  endif

  normal! ^
  return [line('.'), 0]
endfunction

" -- textobj_def {{{1

function! s:textobj_def(keyword, inside, ignore_meta) abort
  let keyword = '\<\%('.escape(a:keyword, '|').'\)\>'

  " helpers
  let Skip = {-> s:skip_terms(["Tuple", "String", "Comment"])}

  " init
  let view = winsaveview()
  let cursor_origin = getcurpos('.')
  let [_, origin_lnr, origin_col, _, _] = cursor_origin

  """ start
  if s:cursor_in_gutter()
    normal! ^
  endif

  if s:cursor_function_metadata()
    while s:cursor_function_metadata()
      normal! j^
    endwhile

    if match(expand("<cword>"), keyword) >= 0
      let cursor_origin = getcurpos('.')
      let [_, origin_lnr, origin_col, _, _] = cursor_origin
    endif
  endif

  let cursor_on_keyword = match(expand("<cword>"), keyword) >= 0
  let on_first_char_of_keyword = cursor_on_keyword && expand("<cword>")[0] ==# s:cursor_char()

  if cursor_on_keyword && !on_first_char_of_keyword
    normal! b
  elseif cursor_on_keyword
    " cursor is on the first character of the keyword or not in a function...
    " though this needs further investigation.
  elseif !cursor_on_keyword
    call search(keyword, 'Wb', 0, 0, Skip)
  else
    call search(keyword, 'W', 0, 0, Skip)
  endif

  if match(expand("<cword>"), keyword) == -1
    return winrestview(view)
  endif

  let keyword_lnr = line('.')

  let dokw = searchpairpos(keyword, '', '\<do\>\:', 'W', Skip, line('.') + 1)

  if dokw != [0, 0]
    " We're dealing with keyword syntax so we're going to bail for now

    return winrestview(view)
    " call search('(', 'W', line('.'))
    " if s:cursor_char() ==# '('
    "   normal! vib
    " else
    "   normal! Wv$
    " endif

    " return 0
    " call setpos("'<", [bufnr('%'), start_lnr, start_col, 0])
    " call setpos("'>", [bufnr('%'), end_lnr, end_col, 0])
    " normal! gv
    " return winrestview(view)
  endif

  if a:inside
    let [start_lnr, _start_col] = searchpairpos(keyword, '', '\<do\>', 'W', Skip)
  else
    let start_lnr = line('.')
    call searchpos('\<do\>', 'W', 0, 0, Skip)
  endif

  let [end_lnr, end_col] = searchpairpos('\<do\>:\@!\|\<fn\>', '', '\<end\>', 'W', Skip)

  let start_col = 1

  if a:inside
    let start_lnr += 1
    let end_lnr -= 1

    if v:operator ==# 'c'
      let start_col = indent(start_lnr) + 1
      exec start_lnr + 1
      let end_col = len(getline(end_lnr))
    else
      let end_col = len(getline(end_lnr)) + 1 " Include \n
      exec start_lnr
    endif
  else
    exec start_lnr

    let end_col = len(getline(end_lnr)) + 1 " Include \n

    if s:is_blank(getline(start_lnr - 1))
      let start_lnr -=1
      let start_col = 1
    endif
  endif

  normal! ^

  if !a:inside && !s:is_blank(getline(line('.') - 1)) && !a:ignore_meta
    normal! k^

    while s:cursor_function_metadata()
      normal! k^
    endwhile

    if start_lnr !=# line('.')
      let start_lnr = line('.') + 1
    endif
  endif

  " echom [origin_lnr, origin_col, start_lnr, start_col, end_lnr, end_col]

  if !a:inside && !s:in_range(origin_lnr, origin_col, [start_lnr, 0], [end_lnr, end_col])
    return winrestview(view)
  elseif a:inside && !s:in_range(origin_lnr, origin_col, [keyword_lnr, 0], [end_lnr + 1, end_col])
    return winrestview(view)
  endif

  let view.lnum = keyword_lnr
  call s:textobj_select_obj(view, start_lnr, start_col, end_lnr, end_col)
endfunction

" -- textobj_comment {{{1

function! s:textobj_comment(inside)
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

  call setpos('.', cursor_origin)

  normal $

  while s:cursor_on_comment() && comment_type ==# s:cursor_outer_syn_name()
    if line('.') == line('$')
      break
    endif

    normal j$
  endwhile

  echom line('.')

  if !s:cursor_on_comment() || comment_type != s:cursor_outer_syn_name()
    normal k$
  endif

  let end_lnr = line('.')

  if a:inside && comment_type ==# 'DocString'
    let start_lnr += 1
    let end_lnr -= 1
  endif

  call s:textobj_select_obj(view, start_lnr, start_col, end_lnr, end_col)
endfunction

" :FromPipe and :ToPipe {{{1

function! s:to_pipe() abort
  let cursor_origin = getcurpos('.')
  let [_, origin_lnr, origin_col, _, _] = cursor_origin
  let line = getline('.')

  " Search for an open paren before the cursor on the current line and jump to it if found.
  let open_pos = searchpos('(', 'b', line('.'), 0, "s:skip()")

  if open_pos == [0, 0]
    " If not found, look backwards for an open paren on the current liine and
    " jump to it if found.
    let open_pos = searchpos('(', '', line('.'), 0, "s:skip()")
  endif

  " Check to see if there are nested parens on the current line
  let is_nested = searchpos('(', 'bn', line('.'), 0, "s:skip()") != [0, 0]

  if !is_nested && s:starts_with_pipe(getline('.'))
    return s:reset(cursor_origin)
  endif

  if open_pos != [0, 0]
    let outer_close_pos = searchpairpos('(', '', ')', 'Wn', 's:skip()')

    " There are no args to unpipe
    if s:empty_parens()
      return s:reset(cursor_origin)
    endif

    " Now we need to see if there are multiple arguments.  We need to match
    " a `(` with a `,`.  Of course, ',' may be present *within* the first arg.
    " This isn't a problem for data structures since we can just skip the
    " highlight groups.  It's tougher when the first arg is a function call with
    " multiple arguments.  In this case we need to see if there is another
    " paren pair within the current parens.  If we do that, we can skip
    " recursive checks for additional nested function calls by skipping
    " everything between the nested parens.

    call s:cursor_move_forward()

    let nested_open_pos = searchpos('(', 'W', outer_close_pos[0], 0, "s:skip()")
    let nested_close_pos = [0, 0]

    if nested_open_pos != [0, 0] " First param has args
      let nested_close_pos = searchpairpos('(', '', ')', '', "s:skip()")
      call cursor(open_pos)
    endif

    " Check if there is one argument
    let F = {-> s:skip() || (nested_open_pos !=# [0, 0] && s:in_range(origin_lnr, origin_pos, nested_open_pos, nested_close_pos)) }
    let comma_pos = searchpos(',', 'W', outer_close_pos[0], 0, F)

    let save_register = @p

    if comma_pos !=# [0, 0]
      " Has one argument
      let save_mark = getpos("'a")
      normal! ma
      call cursor(open_pos)
      call s:cursor_move_forward()
      normal! "pd`a
      call setpos("'a", save_mark)
      normal! "_dW
      if getline(".") == ""
        delete_
      endif
      normal! ==
    else
      normal! "pdib
    endif

    if @p == ""
      let @p = save_register
      return s:reset(cursor_origin)
    endif

    call setpos('.', cursor_origin)

    if is_nested
      normal! B
      normal! "pP
      exec "normal! a\<space>|>\<space>"
    else
      exec "normal! I|>\<space>"
      call append(line('.') - 1, split(@p, "\n"))
    endif

    let @p = save_register

    let save_mark = getpos("'a")
    normal! ma
    call setpos('.', cursor_origin)
    normal! =`a
    call setpos("'a", save_mark)
  else
    return s:reset(cursor_origin)
  endif
endfunction

function! s:from_pipe() abort
  let curr_line = getline(".")
  let prev_line = getline(line('.') - 1)
  let next_line = getline(line('.') + 1)

  " Find out if we're in a nested pipe

  let pipe_pos = searchpos('|>', 'Wn', line('.'), 's:is_string_or_comment()')

  if pipe_pos != [0, 0] 
    " In nested pipe.
    " In this case we are always going to inline-pipe.
    let code = s:get_outer_term()

    if s:cursor_prev_char() != "|"
      normal! "_dt|
    endif

    normal! "_dWf(

    if !s:empty_parens()
      let code = trim(code).", "
    else
      let code = trim(code)
    endif

    let save_p = @p
    let @p = code
    normal! "pp
    let @p = save_p
    return
  else
    " Pipe on each line
    if s:starts_with_pipe(curr_line) && !s:starts_with_pipe(prev_line)
      " We're on the piped line
      let pipe_lnr = line('.')
      let term_lnr = line('.') - 1
      exec term_lnr
      let term = s:get_outer_term()
    elseif !s:starts_with_pipe(curr_line) && s:starts_with_pipe(next_line)
      " Were on the value line
      let term_lnr = line('.')
      let pipe_lnr = line('.') + 1
      exec term_lnr
      let term = s:get_outer_term()
    else
      echom "Cannot unpipe"

      return 0
    endif

    delete_

    let line = s:sub(getline('.'), '|> ', '')
    normal! f(

    if !s:empty_parens()
      let addon = ', '
    else
      let addon = ''
    endif

    let line_parts = split(line, "(")
    let head = line_parts[0]
    let tail_str = join(line_parts[1:], '(')
    let term_line_count = len(split(term, "\n"))
    let term_len = len(split(term, "\n"))
    let joiner = term_len > 1 ? "\n" : ""

    if s:empty_parens()
      let addon = ""
    else
      let addon = term_len > 1 ? "," : ", "
    endif

    let value = split(join(add([head."(", term.addon], tail_str), joiner), "\n")

    call append(line('.'), value)
    delete_
    if term_line_count > 1
      exec "normal! ".(term_line_count + 1)."=j"
    endif
  endif
endfunction

function! s:skip()
  return synIDattr(synID(line('.'), col('.'), 1), "name") =~ '\%(String\|Comment\|CharList\|List\|Map\|Tuple\)'
endfunction

function! s:skip_terms(terms)
  let terms = join(a:terms, '\|')

  return synIDattr(synID(line('.'), col('.'), 1), "name") =~ '\%('.terms.'\)'
endfunction

function! s:reset(pos)
  call setpos('.', a:pos)
  echom "Nothing to pipe"

  return 0
endfunction
