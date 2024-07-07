" Utility {{{1

" Check if cursor in range of two positions.
" Positions are in the form of [line, col].
function! s:in_range(start, end) abort
  let [start_lnr, start_col] = a:start
  let [end_lnr, end_col] = a:end
  let lnr = line('.')
  let col = col('.')

  if lnr > start_lnr && lnr < end_lnr
    return 1
  endif

  if lnr == start_lnr && lnr == end_lnr
    return col >= start_col && col <= end_col
  endif

  if lnr == start_lnr && col >= start_col
    return 1
  endif

  if lnr == end_lnr && col <= end_col
    return 1
  endif

  return 0
endfunction

" Syntax Grammar {{{1

function! s:is_string_or_comment(line, col)
  return s:syntax_name(a:line, a:col) =~ '\%(String\|Comment\|CharList\)'
endfunction

function! s:starts_with_pipe(line)
  return match(trim(a:line), '^|>') >= 0
endfunction

function! s:empty_parens()
  let cursor = getpos(".")
  let save_i = @i
  normal! "iyib
  let is_empty = empty(trim(@i))
  let @i = save_i
  call setpos(".", cursor)

  return is_empty
endfunction

function! s:cursor_term()
  return synIDattr(synID(line('.'), col('.'), 1), "name")
endfunction

function! s:outer_term()
  let terms = map(synstack(line('.'), col('.')), 'synIDattr(v:val,"name")')

  let terms = filter(terms, 'v:val !=# "elixirBlock"')

  if empty(terms) | return '' | endif

  return substitute(substitute(terms[0], 'elixir', '', ''), 'Delimiter', '', '')
endfunction

function! s:get_term(cmd)
  let save_i = @i
  exec 'normal! "i'.a:cmd
  let value = @i
  let @i = save_i

  return value
endfunction

function! s:get_outer_term()
  let outer_term = s:outer_term()

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

" Mix Project  {{{1

function! s:get_mix_project() abort
  let mix_file = findfile("mix.exs", ".;")

  if mix_file == ""
    return {"root": ""}
  endif

  if mix_file == "mix.exs"
    let project_root = getcwd()
  else
    let project_root = getcwd()
  endif

  return {
        \ "root": project_root
        \ }
endfunction

let b:project = s:get_mix_project()
let b:impl_lnr = 0
let b:tpl_lnr = 0

if b:project.root ==# ""
  echom "Not in a mix project"
  finish
endif

function! s:in_live_view() abort
  return search('^\s\+use [A-Z][A-Za-z\.]\+[^\.], .*\%(live_view\|live_component\|Phoenix.LiveView\|Phoenix.LiveComponent\)', 'wn')
endfunction

let s:render_regex = '^\s\+def render('

function! s:in_render() abort
  return match(getline('.'), s:render_regex) != -1 || search(s:render_regex, 'bWn')
endfunction

function! s:has_render() abort
  return search(s:render_regex, 'wn')
endfunction

function! elixir_ext#related() abort
  if s:has_render()
    if s:in_live_view()
      if s:in_render()
        let b:tpl_lnr = line('.')
        if b:impl_lnr
          exec ":".b:impl_lnr
        else
          call search('^\s\+def mount(')
        endif
      else
        let b:impl_lnr = line('.')
        if b:tpl_lnr
          exec ":".b:tpl_lnr
        else
          call search('^\s\+def render(')
        endif
      endif
    endif
  else
    if &ft ==# 'elixir'
      let basename = substitute(expand("%:p"), '\.ex$', '.html.heex', '')
    else
      let basename = substitute(expand("%:p"), '\.html.heex$', '.ex', '')
    endif
    exec "e ".basename
  endif
endfunction

" :FromPipe and :ToPipe {{{1

function! elixir_ext#to_pipe() abort
  let cursor_origin = getcurpos('.')
  let line = getline('.')

  let open_pos = searchpos('(', 'b', line('.'), 0, "s:skip()") " Move cursor to this position

  if open_pos == [0, 0]
    let open_pos = searchpos('(', '', line('.'), 0, "s:skip()") " Move cursor to this position
  endif

  let is_nested = searchpos('(', 'bn', line('.'), 0, "s:skip()") != [0, 0]

  if !is_nested && s:starts_with_pipe(getline('.'))
    call s:reset(cursor_origin)

    return
  endif

  if open_pos != [0, 0]
    let close_pos = searchpairpos('(', '', ')', 'Wn', 's:skip()')

    " There are no args to unpipe
    if s:empty_parens()
      return s:reset(cursor_origin)
    endif

    " Now we need to see if there are multiple arguments
    " We need to match a `(` with a `,`.  Of course, ',' can belong to the
    " first arg.  This isn't a problem for data structures since we can just
    " skip the highlight groups.  It's tougher when the first arg is
    " a function call with multiple arguments.  We need to see if there is
    " another paren pair within the current parens.  If we do that, we can
    " skip recursive checks for additional nested function calls by skipping
    " everything between the nested parens.

    exec "normal! 1\<space>"

    let nested_open_pos = searchpos('(', 'W', close_pos[0], 0, "s:skip()")
    let nested_close_pos = [0, 0]

    if nested_open_pos != [0, 0] " First param has args
      let nested_close_pos = searchpairpos('(', '', ')', '', "s:skip()")
      call cursor(open_pos)
    endif

    " Check if there is one argument
    let F = {-> s:skip() || (nested_open_pos !=# [0, 0] && s:in_range(nested_open_pos, nested_close_pos)) }
    let comma_pos = searchpos(',', 'W', close_pos[0], 0, F)

    let save_register = @p

    if comma_pos !=# [0, 0]
      " Has one argument
      let save_mark = getpos("'a")
      normal! ma
      call cursor(open_pos)
      exec "normal! 1\<space>"
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

function! elixir_ext#from_pipe() abort
  let curr_line = getline(".")
  let prev_line = getline(line('.') - 1)
  let next_line = getline(line('.') + 1)

  " Find out if we're in a nested pipe

  let pipe_pos = searchpos('|>', 'Wn', line('.'), 's:is_string_or_comment()')

  if pipe_pos != [0, 0] 
    " In nested pipe.
    " In this case we are always going to inline-pipe.
    let code = s:get_outer_term()

    if getline('.')[col('.') - 1] != "|"
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
      let pipe_lnr = line('.')
      let term_lnr = line('.') - 1
      exec term_lnr
      let term = s:get_outer_term()
      delete_
    elseif !s:starts_with_pipe(curr_line) && s:starts_with_pipe(next_line)
      let term_lnr = line('.')
      let pipe_lnr = line('.') + 1
      exec term_lnr
      let term = s:get_outer_term()
      delete_
    else
      echom "Cannot unpipe"

      return 0
    endif

    let line = substitute(getline('.'), '|> ', '', '')
    normal! f(

    if !s:empty_parens()
      let addon = ', '
    else
      let addon = ''
    endif

    let line_parts = split(line, "(")
    let head = line_parts[0]
    let tail_str = join(line_parts[1:], '(')
    let is_multiline = len(split(term, "\n")) > 1
    delete_
    let term_len = len(split(term, "\n"))
    let joiner = term_len > 1 ? "\n" : ""
    let addon = term_len > 1 ? "," : ", "
    let value = split(join(add([head."(", term.addon], tail_str), joiner), "\n")

    call append(line('.'), value)
    delete_
  endif
endfunction

function! s:skip()
  return synIDattr(synID(line('.'), col('.'), 1), "name") =~ '\%(String\|Comment\|CharList\|List\|Map\|Tuple\)'
endfunction

function! s:reset(pos)
  call setpos('.', a:pos)
  echom "Nothing to pipe"

  return 0
endfunction
