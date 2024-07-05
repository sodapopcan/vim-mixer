if exists('g:autoloaded_phx') || &cp
  finish
endif
let g:autoloaded_phx = 1

" Utility {{{1

function! s:sub(s, p, r) abort
  return substitute(a:s, a:p, a:r, '')
endfunction

function! s:command_exists(cmd) abort
  return exists(':'.a:cmd) == 2
endfunction

function! s:matches(string, pattern)
  return match(a:string, a:pattern) != -1
endfunction

" Elixir Utility

function! s:starts_with_pipe(line)
  return s:matches(trim(a:line), '^|>')
endfunction

function! phx#from_pipe() abort
  let curr_line = getline(".")
  let prev_line = getline(line('.') - 1)
  let next_line = getline(line('.') + 1)

  if s:starts_with_pipe(curr_line) && !s:starts_with_pipe(prev_line)
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
  let line = s:sub(pipe_line, '|> ', '')
  normal! f(

  if searchpair('(', '', ',', 'Wn', 'SkipIt()')
    let addon = ', '
  else
    let addon = ''
  endif

  let line = s:sub(line, '(', "(".value.addon)
  call setline(value_lnr, line)
endfunction

function! InRange(start, end)
  let [start_lnr, start_col] = a:start
  let [end_lnr, end_col] = a:end
  let lnr = line('.')
  let col = col('.')

  if lnr > start_lnr && lnr < end_lnr | return 1 | endif
  if lnr == start_lnr && lnr == end_lnr && col >= start_col && col <= end_col | return 1 | endif
  if lnr == end_lnr && col <= end_col | return 1 | endif
  return 0
endfunction

" function! s:SelectionText(sel) abort
"   let [start, end] = [a:sel.start, a:sel.end]
"   let lines = getbufline(a:sel.bufnr, start[1], end[1])
"   let lines[-1] = strpart(lines[-1] . "\n", 0, end[2])
"   let lines[0] = strpart(lines[0], start[2] - 1)
"   if !get(a:sel, 'inclusive') && end[1] < v:maxcol
"     let lines[-1] = substitute(lines[-1], '.$', '', '')
"   endif
"   return join(lines, "\n")
" endfunction

function! EmptyDelimiters(start, end)
  let [start_lnr, start_col] = a:start
  let [end_lnr, end_col] = a:end

  if start_lnr == end_lnr && end_col == start_col + 1
    return 1
  else
    return 0
  endif
endfunction

function! SkipIt()
  return synIDattr(synID(line('.'), col('.'), 1), "name") =~ '\%(String\|Comment\|CharList\|Map\|Tuple\)'
endfunction

function! s:reset(pos)
  call setpos('.', a:pos)
  echom "Nothing to pipe"
  return 0
endfunction

function! phx#to_pipe() abort
  let cursor_origin = getcurpos('.')
  let line = getline('.')

  if !s:starts_with_pipe(line)
    normal! ^

    let open_pos = searchpos('(', '', line('.'), 0, "SkipIt()") " Move cursor to this position
    if open_pos != [0, 0] " This line starts with a function call
      let close_pos = searchpairpos('(', '', ')', 'Wn', 'SkipIt()')

      " There are no args to unpipe
      if EmptyDelimiters(open_pos, close_pos)
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

      let nested_open_pos = searchpos('(', 'W', close_pos[0], 500, 'SkipIt()')
      let nested_close_pos = [0, 0]

      if nested_open_pos != [0, 0] " First param has args
        let nested_close_pos = searchpairpos('(', '', ')', '', "SkipIt()")
        call cursor(open_pos)
      endif

      " Check if there is one argument
      let F = {-> SkipIt() || (nested_open_pos !=# [0, 0] && InRange(nested_open_pos, nested_close_pos)) }
      let comma_pos = searchpos(',', 'W', close_pos[0], 500, F)

      let save_register = @p

      " Has one argument
      if comma_pos !=# [0, 0]
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

      call setpos('.', cursor_origin)

      exec "normal! I|>\<space>"
      call append(line('.') - 1, split(@p, "\n"))

      let @p = save_register

      let save_mark = getpos("'a")
      normal! ma
      call setpos('.', cursor_origin)
      normal! =`a
      call setpos("'a", save_mark)
    else
      return s:reset(cursor_origin)
    endif
  else
    return s:reset(cursor_origin)
  endif
endfunction

" Project {{{1

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

function! phx#related() abort
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
      let basename = s:sub(expand("%:p"), '\.ex$', '.html.heex')
    else
      let basename = s:sub(expand("%:p"), '\.html.heex$', '.ex')
    endif
    exec "e ".basename
  endif
endfunction

function! phx#define_command() abort
  if !s:command_exists("R")
    command! -buffer -nargs=0 R call phx#related()
  endif

  if !s:command_exists("FromPipe")
    command! -buffer -nargs=0 FromPipe call phx#from_pipe()
  endif

  if !s:command_exists("ToPipe")
    command! -buffer -nargs=0 ToPipe call phx#to_pipe()
  endif
endfunction
