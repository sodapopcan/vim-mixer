" if exists('g:loaded_phx') || &cp
"   finish
" endif
" let g:loaded_phx = 1

function s:get_mix_project()
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

function s:in_live_view()
  return search('^\s\+use \%([A-Z][A-Za-z\.]\+[^\.], :live_view\|Phoenix.LiveView\)', 'wn')
endfunction

function s:in_render()
  let render_regex = '^\s\+def render('

  return match(getline('.'), render_regex) != -1 || search(render_regex, 'bWnn')
endfunction

function s:related(pattern) abort
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
endfunction

command! -nargs=? R call <sid>related(0<f-args>)
