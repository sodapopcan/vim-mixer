if exists("g:autoloaded_elixir_ext_pipe")
finish
endif
let g:autoloaded_elixir_ext_pipe = 1

function! elixir_ext#pipe#to_pipe() abort
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
    if elixir_ext#util#empty_parens()
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
    let F = {-> s:skip() || (nested_open_pos !=# [0, 0] && elixir_ext#util#in_range(nested_open_pos, nested_close_pos)) }
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

function! elixir_ext#pipe#from_pipe() abort
  let curr_line = getline(".")
  let prev_line = getline(line('.') - 1)
  let next_line = getline(line('.') + 1)

  " Find out if we're in a nested pipe

  if 0
  elseif s:starts_with_pipe(curr_line) && !s:starts_with_pipe(prev_line)
    let value_lnr = line('.') - 1
    let value = trim(prev_line)
    let pipe_lnr = line('.')
    let pipe_line = curr_line
  elseif !s:starts_with_pipe(curr_line) && s:starts_with_pipe(next_line)
    let value_lnr = line('.')
    let value = trim(curr_line)
    let pipe_lnr = line('.') + 1
    let pipe_line = next_line
  else
    echom "Cannot unpipe"
    return 0
  end

  exec value_lnr."d_"
  let line = substitute(pipe_line, '|> ', '', '')
  normal! f(

  if !elixir_ext#util#empty_parens()
    let addon = ', '
  else
    let addon = ''
  endif

  let line = substitute(line, '(', "(".value.addon, '')
  call setline(value_lnr, line)
endfunction

function! s:skip()
  return synIDattr(synID(line('.'), col('.'), 1), "name") =~ '\%(String\|Comment\|CharList\|List\|Map\|Tuple\)'
endfunction

function! s:starts_with_pipe(line)
  return match(trim(a:line), '^|>') >= 0
endfunction

function! s:reset(pos)
  call setpos('.', a:pos)
  echom "Nothing to pipe"
  return 0
endfunction
