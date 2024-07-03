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

function! SkipIt()
  return synIDattr(synID(line('.'), col('.'), 1), "name") =~ '\%(String\|Comment\|CharList\|Map\|Tuple\)'
endfunction

function! phx#to_pipe() abort
  let line = getline('.')
  let msg = "Nothing to pipe"

  if !s:starts_with_pipe(line)
    let cursor_origin = getcurpos('.')

    normal! ^
    if search('(', '', line('.'), 0, "SkipIt()") != 0
      let closing_paren_lnr = searchpair('(', '', ')', 'Wn', 'SkipIt()') != 0

      if closing_paren_lnr != 0
        let save = @a
        normal! "adibk
        call append(line('.'), @a)
        exec "normal! j==jI|>\<space>\<esc>"
        let @a = save
        " if closing_paren_lnr != line('.')
        "   normal! J
        " endif
      endif
    else
      call setpos('.', cursor_origin)
      echom msg
    endif
  else
    echom msg
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
