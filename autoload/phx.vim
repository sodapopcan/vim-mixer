if exists('g:autoloaded_phx') || &cp
  finish
endif
let g:autoloaded_phx = 1

" Utility {{{1

function! s:sub(s, p, r)
  return substitute(a:s, a:p, a:r, '')
endfunction

function! s:command_exists(cmd)
  return exists(':'.a:cmd) == 2
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
  return search('^\s\+use \%([A-Z][A-Za-z\.]\+[^\.], .*live_view\|Phoenix.LiveView\)', 'wn')
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

function! phx#define_command()
  if !s:command_exists("R")
    command! -buffer -nargs=0 R call phx#related()
  endif
endfunction
