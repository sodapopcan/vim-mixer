" Location:     autoload/elixir_ext.vim
" Maintainer:   Andrew Haust <https://andrew.hau.st>

" Utility {{{1

function! s:sub(str, pat, rep)
  return substitute(a:str, a:pat, a:rep, '')
endfunction

function! s:matches(str, pat)
  return match(str, path) >= 0
endfunction

" From tpope

function! s:to_elixir_alias(word)
  return substitute(s:camelcase(a:word),'^.','\u&','')
endfunction

function! s:camelcase(word)
  let word = substitute(a:word, '-', '_', 'g')
  if word !~# '_' && word =~# '\l'
    return substitute(word,'^.','\l&','')
  else
    return substitute(word,'\C\(_\)\=\(.\)','\=submatch(1)==""?tolower(submatch(2)) : toupper(submatch(2))','g')
  endif
endfunction

" Check if cursor is in range of two positions.
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

function! s:command_exists(cmd)
  return exists(":".a:cmd) == 2
endfunction

" Init {{{1

function! elixir_ext#init() abort
  call s:init_mix_project()

  let macros = [['def', 'f'], ['defmodule', 'M']]

  for [macro, obj] in macros
    exec "vnoremap <silent> <buffer> i".obj." :\<c-u>call <sid>textobj_def('".macro."', 1)\<cr>"
    exec "vnoremap <silent> <buffer> a".obj." :\<c-u>call <sid>textobj_def('".macro."', 0)\<cr>"
    exec "onoremap <silent> <buffer> i".obj." :call <sid>textobj_def('".macro."', 1)\<cr>"
    exec "onoremap <silent> <buffer> a".obj." :call <sid>textobj_def('".macro."', 0)\<cr>"
  endfor

  vnoremap <silent> <buffer> im :<c-u>call <sid>textobj_map(1)<cr>
  vnoremap <silent> <buffer> am :<c-u>call <sid>textobj_map(0)<cr>
  onoremap <silent> <buffer> im :call <sid>textobj_map(1)<cr>
  onoremap <silent> <buffer> am :call <sid>textobj_map(0)<cr>

  if !s:command_exists("R")
    command -buffer -nargs=0 R call s:related()
  endif

  if !s:command_exists("ToPipe")
    command -buffer -nargs=0 ToPipe call s:to_pipe()
  endif

  if !s:command_exists("FromPipe")
    command -buffer -nargs=0 FromPipe call s:from_pipe()
  endif

  if !s:command_exists("Mix")
    command -buffer -complete=custom,ElixirExtMixComplete -nargs=* Mix call s:Mix(<f-args>)
  endif

  if !s:command_exists("Deps")
    command -buffer -nargs=* -range Deps call s:Deps(<range>, <f-args>)
  endif

  if !s:command_exists("Generate")
    command -buffer -complete=custom,ElixirExtGenerateComplete -nargs=* Generate call s:Generate(<f-args>)
  endif
endfunction


" Syntax Helpers {{{1

function! s:cursor_char()
  return getline('.')[col('.') - 1]
endfunction

function! s:cursor_term()
  return s:sub((synIDattr(synID(line('.'), col('.'), 1), "name")), '^elixir', '')
endfunction

function! s:cursor_prev_char()
  return getline('.')[col('.') - 2]
endfunction

function! s:cursor_in_gutter()
  let leading_whitespace_len = len(matchstr(getline('.'), '^\s\+'))

  return col('.') <= leading_whitespace_len
endfunction

function! s:cursor_function_metadata()
  return s:outer_term() ==# 'Variable' || s:outer_term() ==# 'DocString' || s:outer_term() ==# 'DocStringDelimiter'
endfunction

function! s:is_string_or_comment()
  return s:cursor_term() =~ '\%(String\|Comment\|CharList\)'
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

function! s:outer_term()
  let terms = map(synstack(line('.'), col('.')), 'synIDattr(v:val,"name")')

  let terms = filter(terms, 'v:val !=# "elixirBlock"')

  if empty(terms) | return '' | endif

  return s:sub(s:sub(terms[0], 'elixir', ''), 'Delimiter', '')
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


" Text Objects {{{1

function! s:textobj_map(inside) abort
  let char = s:cursor_char()
  let current_pos = getpos('.')

  let Skip = {-> s:skip_terms(["Tuple", "String", "Comment"])}
  let SearchForward = {-> searchpairpos('%{', '', '}', 'W', Skip)}
  let SearchBack = {-> searchpairpos('%{', '', '}', 'Wb', Skip)}

  if char == "%"
    let [start_lnr, start_col] = [line('.'), col('.')]
    let [end_lnr, end_col] = SearchForward()

    if a:inside
      let start_col += 2
    endif
  elseif char == "{" && s:cursor_prev_char() == "%"
    let [start_lnr, start_col] = [line('.'), col('.')]
    let [end_lnr, end_col] = SearchForward()

    if a:inside
      let start_col += 1
    else
      let start_col -= 1
    endif
  else
    let [start_lnr, start_col] = SearchBack()
    let [end_lnr, end_col] = SearchForward()

    if a:inside
      let start_col += 2
    endif
  endif

  if a:inside
    let end_col -= 1
  endif

  if getline(end_lnr)[0] ==# "}" && a:inside
    let end_lnr -= 1
    let end_col = len(end_lnr) + 2 " Grab the \n as well
  endif

  if reverse(getline(end_lnr))[0] ==# "}" && !a:inside
    let end_lnr += 1
  endif

  call setpos('.', current_pos)

  call setpos("'<", [bufnr('%'), start_lnr, start_col, 0])
  call setpos("'>", [bufnr('%'), end_lnr, end_col, 0])
  normal! gv
endfunction

function! s:textobj_def(keyword, inside) abort
  " helpers
  let Skip = {-> s:skip_terms(["Tuple", "String", "Comment"])}

  " init
  let cursor_origin = getcurpos('.')

  """ start
  if s:cursor_in_gutter()
    normal! ^
  endif

  let cursor_on_keyword = match(expand("<cword>"), a:keyword) >= 0
  let on_first_char_of_keyword = cursor_on_keyword && s:cursor_char() == a:keyword[0]

  if cursor_on_keyword && !on_first_char_of_keyword
    normal! b
  elseif s:cursor_function_metadata()
    call search('\<'.a:keyword.'\>', 'W', 0, 0, Skip)
  elseif !cursor_on_keyword
    call search('\<'.a:keyword.'\>', 'Wb', 0, 0, Skip)
  else
    " cursor is on the first character of the keyword or not in a function...
    " though this needs further investigation.
  endif

  let [start_lnr, _start_col] = searchpos('\<do\>', 'W', 0, 0, Skip)
  let [end_lnr, end_col] = searchpairpos('\<do\>:\@!\|\<fn\>', '', '\<end\>', 'W', Skip)

  let start_col = 0

  if a:inside
    let start_lnr += 1
    let end_lnr -= 1
  endif

  let end_col = len(getline(end_lnr)) + 1 " Include \n

  call setpos('.', cursor_origin)

  if start_lnr ==# end_lnr + 1
    return 0
  endif

  exec start_lnr
  normal! ^

  if !a:inside && !empty(trim(getline(line('.') - 1)))
    normal! k^
    while s:cursor_function_metadata()
      normal! k^
    endwhile

    if start_lnr !=# line('.')
      let start_lnr = line('.') + 1
    endif
  endif

  if !a:inside
    " let start_col = len(getline(start_lnr - 1)) + 1
    " let start_lnr = start_lnr - 1
    " let end_lnr -= 1
  endif

  call setpos('.', cursor_origin)
  " echom [start_lnr, start_col, end_lnr, end_col]

  if !s:in_range([start_lnr, start_col], [end_lnr, end_col])
    return 0
  endif

  call setpos("'<", [bufnr('%'), start_lnr, start_col, 0])
  call setpos("'>", [bufnr('%'), end_lnr, end_col, 0])
  normal! gv
endfunction

" Mix {{{1

function! s:root(path) abort
  return b:mix_project.root.'/'.a:path
endfunction

function! s:is_mix_project() abort
  return exists("b:mix_project")
endfunction

function! s:init_mix_project() abort
  let mix_file = findfile("mix.exs", ".;")

  if mix_file == ""
    return 0
  endif

  if !exists("b:mix_project")
    let b:mix_project = {}
  endif

  let b:impl_lnr = 0
  let b:tpl_lnr = 0
  let project_root = s:sub(mix_file, 'mix.exs$', '')
  if project_root ==# ""
    let project_root = "."
  endif

  try
    let contents = join(readfile(mix_file), "\n")
    let project_name = matchstr(contents, 'def project\_.*app:\s\+:\zs[a-z][A-Za-z0-9_]\+\ze,')
  catch
    let project_name = ""
  endtry

  let b:mix_project["root"] = project_root
  let b:mix_project["name"] = project_name

  autocmd! DirChanged * let b:mix_project.root = s:sub(findfile("mix.exs", ".;"), 'mix.exs$', '')

  if g:elixir_ext_define_projections
    let g:projectionist_heuristics["mix.exs"] = {
          \   'lib/'.b:mix_project.name.'.ex': {
          \     'type': 'domain'
          \   },
          \   'lib/'.b:mix_project.name.'/*.ex': {
          \     'type': 'domain',
          \     'alternate': 'test/'.b:mix_project.name.'/{}_test.exs',
          \     'template': ['defmodule '.s:to_elixir_alias(b:mix_project.name).'.{camelcase|capitalize|dot} do', 'end']
          \   },
          \   'lib/'.b:mix_project.name.'_web.ex': {
          \     'type': 'web'
          \   },
          \   'lib/'.b:mix_project.name.'_web/*.ex': {
          \     'type': 'web',
          \     'alternate': 'test/'.b:mix_project.name.'_web/{}_test.exs'
          \   },
          \   'test/'.b:mix_project.name.'/*_test.exs': {
          \     'type': 'test',
          \     'alternate': 'lib/'.b:mix_project.name.'/{}.ex',
          \     'template': ['defmodule '.s:to_elixir_alias(b:mix_project.name).'.{camelcase|capitalize|dot}Test do', '  use ExUnit.Case', '', '  @subject {camelcase|capitalize|dot}', 'end'],
          \   },
          \   'mix.exs': {
          \     'type': 'mix',
          \     'alternate': 'mix.lock',
          \     'dispatch': 'mix deps.get'
          \   },
          \   'mix.lock': {
          \     'type': 'lock',
          \     'alternate': 'mix.exs',
          \     'dispatch': 'mix deps.get'
          \   },
          \   'config/*.exs': {
          \     'type': 'config',
          \     'related': 'config/config.exs'
          \   },
          \   'lib/'.b:mix_project.name.'_web/router.ex': {
          \     'type': 'router',
          \     'alternate': 'lib/'.b:mix_project.name.'_web/endpoint.ex'
          \   },
          \   'lib/'.b:mix_project.name.'_web/endpoint.ex': {
          \     'type': 'endpoint',
          \     'alternate': 'lib/'.b:mix_project.name.'_web/router.ex'
          \   },
          \   'priv/repo/migrations/*.exs': { 'type': 'migration', 'dispatch': 'mix ecto.migrate' }
          \ }

    let application_file = ""
    let application_files = [
          \   "lib/".b:mix_project.name."/application.ex",
          \   "lib/".b:mix_project.name."/app.ex",
          \   "lib/".b:mix_project.name."_application.ex",
          \   "lib/".b:mix_project.name."_app.ex"
          \ ]

    for file in application_files
      if filereadable(s:root(file))
        let application_file = s:sub(s:root(file), b:mix_project.root, '')
        break
      endif
    endfor

    if !empty(application_file)
      let g:projectionist_heuristics["mix.exs"][application_file] = {'type': 'application'}
    endif
  endif
endfunction

function! s:Mix(...) abort
  if s:command_exists("Dispatch")
    exec "Dispatch mix ".join(a:000, " ")
  else
    call system("mix ".join(a:000, " "))
  endif
endfunction

function! s:Deps(range, ...) abort
  let args = join(a:000, " ")

  if a:range == 1
    let args = args." ".matchstr(getline("."), '\%(\s\+\)\?{:\zs\w\+')
  endif

  if s:command_exists("Dispatch")
    exec "Dispatch mix deps.".args
  else
    call system("mix deps.".args)
  endif
endfunction

function! ElixirExtMixComplete(A, L, P) abort
  return system("ls -1 ".s:root("deps/**/*/mix/tasks/*.ex | xargs basename | sed s/\.ex$//"))
endfunction

let g:elixir_ext_generators = {
      \   'repo': 'ecto.gen.repo',
      \   'migration': 'ecto.gen.migration',
      \   'auth': 'phx.gen.auth',
      \   'cert': 'phx.gen.cert',
      \   'channel': 'phx.gen.channel',
      \   'context': 'phx.gen.context',
      \   'embedded': 'phx.gen.embedded',
      \   'gen': 'phx.gen',
      \   'html': 'phx.gen.html',
      \   'json': 'phx.gen.json',
      \   'live': 'phx.gen.live',
      \   'notifier': 'phx.gen.notifier',
      \   'presence': 'phx.gen.presence',
      \   'release': 'phx.gen.release',
      \   'schema': 'phx.gen.schema',
      \   'secret': 'phx.gen.secret',
      \   'socket': 'phx.gen.socket'
      \ }

function! s:Generate(...) abort
  let task = g:elixir_ext_generators[a:1]

  if s:command_exists("Dispatch")
    exec "Dispatch mix ".task." ".join(a:000[1:])
  else
    call system("mix ".task." ".join(a:000[1:]))
  endif
endfunction

function! ElixirExtGenerateComplete(A, L, P) abort
  return join(keys(g:elixir_ext_generators), "\n")
endfunction


" Phoenix {{{1

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

function! s:related() abort
  if !exists("b:mix_project")
    return
  endif

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


" Ecto {{{1

function! s:EditMigration(type, ...) abort

endfunction

" :FromPipe and :ToPipe {{{1

function! s:to_pipe() abort
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
