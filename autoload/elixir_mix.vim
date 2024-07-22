" Location:     autoload/elixir_mix.vim
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

function! s:to_elixir_alias(word)
  return substitute(s:camelcase(a:word),'^.','\u&','')
endfunction

function! s:camelcase(word) " From tpope
  let word = substitute(a:word, '-', '_', 'g')
  if word !~# '_' && word =~# '\l'
    return substitute(word,'^.','\l&','')
  else
    return substitute(word,'\C\(_\)\=\(.\)','\=submatch(1)==""?tolower(submatch(2)) : toupper(submatch(2))','g')
  endif
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

function! elixir_mix#init() abort
  call s:init_mix_project()

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
    command -buffer -complete=custom,ElixirMixMixComplete -nargs=* Mix call s:Mix(<f-args>)
  endif

  if !s:command_exists("Deps")
    command -buffer -nargs=* -range Deps call s:Deps(<range>, <line1>, <line2>, <f-args>)
  endif

  if !s:command_exists("Generate")
    command -buffer -complete=custom,ElixirMixGenerateComplete -nargs=* Generate call s:Generate(<f-args>)
  endif

  if !s:command_exists("ToPipe")
    command -buffer -nargs=0 ToPipe call s:to_pipe()
  endif

  if !s:command_exists("FromPipe")
    command -buffer -nargs=0 FromPipe call s:from_pipe()
  endif

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

  vnoremap <silent> <buffer> iq :<c-u>call <sid>textobj_def('quote', 1, 1)<cr>
  vnoremap <silent> <buffer> aq :<c-u>call <sid>textobj_def('quote', 0, 1)<cr>
  onoremap <silent> <buffer> iq :<c-u>call <sid>textobj_def('quote', 1, 1)<cr>
  onoremap <silent> <buffer> aq :<c-u>call <sid>textobj_def('quote', 0, 1)<cr>

  vnoremap <silent> <buffer> id :<c-u>call <sid>textobj_block(1)<cr>
  vnoremap <silent> <buffer> ad :<c-u>call <sid>textobj_block(0)<cr>
  onoremap <silent> <buffer> id :<c-u>call <sid>textobj_block(1)<cr>
  onoremap <silent> <buffer> ad :<c-u>call <sid>textobj_block(0)<cr>

  vnoremap <silent> <buffer> ic :<c-u>call <sid>textobj_comment(1)<cr>
  vnoremap <silent> <buffer> ac :<c-u>call <sid>textobj_comment(0)<cr>
  onoremap <silent> <buffer> ic :<c-u>call <sid>textobj_comment(1)<cr>
  onoremap <silent> <buffer> ac :<c-u>call <sid>textobj_comment(0)<cr>

  vnoremap <silent> <buffer> im :<c-u>call <sid>textobj_map(1)<cr>
  vnoremap <silent> <buffer> am :<c-u>call <sid>textobj_map(0)<cr>
  onoremap <silent> <buffer> im :<c-u>call <sid>textobj_map(1)<cr>
  onoremap <silent> <buffer> am :<c-u>call <sid>textobj_map(0)<cr>

  vnoremap <silent> <buffer> iS :<c-u>call <sid>textobj_sigil(1)<cr>
  vnoremap <silent> <buffer> aS :<c-u>call <sid>textobj_sigil(0)<cr>
  onoremap <silent> <buffer> iS :<c-u>call <sid>textobj_sigil(1)<cr>
  onoremap <silent> <buffer> aS :<c-u>call <sid>textobj_sigil(0)<cr>
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
  return s:sub((synIDattr(synID(line('.'), col('.'), 0), "name")), '^elixir', '')
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

  return terms[0] ==# 'elixirMixLambda'
endfunction

function! s:cursor_function_metadata()
  return s:cursor_synstack_str() =~ 'Comment\|DocString\|Variable'
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


" Mix - helpers {{{1

function! s:root(path) abort
  return b:elixir_mix_project.root.'/'.a:path
endfunction

function! s:is_mix_project() abort
  return exists("b:elixir_mix_project")
endfunction

" Mix - project {{{1

function! s:init_mix_project() abort
  let mix_file = findfile("mix.exs", ".;")

  if mix_file == ""
    return 0
  endif

  if !exists("g:elixir_mix_projects")
    let g:elixir_mix_projects = {}
  endif

  if !exists("b:elixir_mix_project")
    let b:elixir_mix_project = {}
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

  if !has_key(g:elixir_mix_projects, project_root)
    let g:elixir_mix_projects[project_root] = {
          \   "root": project_root,
          \   "name": project_name,
          \   "alias": s:to_elixir_alias(project_name),
          \   "tasks": ""
          \ }

    call s:populate_mix_tasks()
  endif

  let b:elixir_mix_project = g:elixir_mix_projects[project_root]

  autocmd! DirChanged * let b:elixir_mix_project.root = s:sub(findfile("mix.exs", ".;"), 'mix.exs$', '')

  let g:elixir_mix_projections = get(g:, "elixir_mix_projections", "replace")

  if g:elixir_mix_projections !=# "disable"
    call s:define_projections()
  endif
endfunction

" Mix - tasks {{{1

function! s:populate_mix_tasks()
  " Thanks @mhandberg for the awk stuff
  let mix_help = "mix help | awk -F ' ' '{printf \"%s\\n\", $2}' | grep -E \"[^-#]\\w+\""

  if exists("*job_start")
    call job_start(["sh", "-c", mix_help], {
          \   "out_cb": function("s:gather_mix_tasks"),
          \   "exit_cb": function("s:set_mix_tasks"),
          \   "mode": "nl"
          \ })
  elseif exists("*jobstart")
    call jobstart(["sh", "-c", mix_help], {
          \   "on_stdout": function("s:gather_mix_tasks"),
          \   "on_exit": function("s:set_mix_tasks"),
          \   "mode": "nl"
          \ })
  endif
endfunction

function! s:gather_mix_tasks(_channel, result)
  let g:elixir_mix_tasks = get(g:, "elixir_mix_tasks", [])
  call add(g:elixir_mix_tasks, a:result)
endfunction

function! s:set_mix_tasks(_id, _status)
  let b:elixir_mix_project.tasks = join(g:elixir_mix_tasks, "\n")
  unlet g:elixir_mix_tasks
endfunction

" Mix - :Mix {{{1

function! s:Mix(...) abort
  if a:1 =~ '^-'
    let env = 'MIX_ENV='.a:1[1:].' '
    let args = a:000[1:]
  else
    let env = ''
    let arg = a:000
  endif

  if s:command_exists("Dispatch")
    exec "Dispatch ".env."mix ".join(args, " ")
  else
    call system(env."mix ".join(args, " "))
  endif
endfunction


" Mix - :Deps {{{1

function! s:Deps(range, line1, line2, ...) abort
  if a:1 == '-add'
    call s:get_deps(a:2)

    return
  endif

  let args = join(a:000, " ")

  if a:range > 0
    for lnr in range(a:line1, a:line2)
      let args = args." ".matchstr(getline(lnr), '\%(\s\+\)\?{:\zs\w\+')
    endfor
  endif

  if s:command_exists("Dispatch")
    exec "Dispatch mix deps.".args
  else
    call system("mix deps.".args)
  endif
endfunction

function! s:get_deps(dep) abort
  let cmd = 'mix hex.info '.a:dep
  let g:elixir_mix_deps_dep = a:dep

  if exists("*job_start")
    call job_start(["sh", "-c", cmd], {
          \   "out_cb": function("s:gather_dep_output"),
          \   "exit_cb": function("s:append_dep"),
          \   "mode": "nl"
          \ })
  elseif exists("*jobstart")
    call jobstart(["sh", "-c", cmd], {
          \   "on_stdout": function("s:gather_dep_output"),
          \   "on_exit": function("s:append_dep"),
          \   "mode": "nl"
          \ })
  endif
endfunction

function! s:gather_dep_output(_channel, line) abort
  let g:elixir_mix_dep_output = get(g:, "elixir_mix_dep_output", [])
  call add(g:elixir_mix_dep_output, a:line)
endfunction

function! s:append_dep(_id, _status) abort
  let output = join(g:elixir_mix_dep_output, "\n")
  let dep = matchstr(output, "{:".g:elixir_mix_deps_dep.",.*}")
  unlet g:elixir_mix_deps_dep g:elixir_mix_dep_output

  call append(line("."), [dep])
  normal! j==

  if match(getline(line(".") + 1), "\]$") == -1
    exec "normal! A,\<esc>^"
  else
    exec "normal! kA,\<esc>j^"
  endif

  write
endfunction

function! ElixirMixMixComplete(A, L, P) abort
  return b:elixir_mix_project.tasks
endfunction

" Mix - :Generate {{{1

let g:elixir_mix_generators = {
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
  let task = g:elixir_mix_generators[a:1]

  if s:command_exists("Dispatch")
    exec "Dispatch mix ".task." ".join(a:000[1:])
  else
    call system("mix ".task." ".join(a:000[1:]))
  endif
endfunction

function! ElixirMixGenerateComplete(A, L, P) abort
  return join(keys(g:elixir_mix_generators), "\n")
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
  if !exists("b:elixir_mix_project")
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

" Text Objects - helpers {{{1

function! s:textobj_select_obj(view, start_lnr, start_col, end_lnr, end_col)
  let g:elixir_mix_view = a:view

  if v:operator ==# 'c'
    unlet g:elixir_mix_view.lnum
    unlet g:elixir_mix_view.col
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
      \ :call winrestview(g:elixir_mix_view)<bar>
      \ :unlet g:elixir_mix_view<bar>
      \ :normal! ^<cr>

function! s:adjust_whitespace(start_lnr, start_col)
  let [start_lnr, start_col] = [a:start_lnr, a:start_col]

  if a:start_lnr > 1 && s:is_blank(getline(a:start_lnr - 1))
    let start_lnr -=1
    let start_col = 1
  endif

  return [start_lnr, start_col]
endfunction

function! s:adjust_block_region(inside, start_lnr, start_col, end_lnr, end_col) abort
  let [start_lnr, start_col, end_lnr, end_col] = [a:start_lnr, a:start_col, a:end_lnr, a:end_col]

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
    let [start_lnr, start_col] = s:adjust_whitespace(start_lnr, start_col)

    if start_col == 0
      let start_col = 1
    endif

    let end_col = len(getline(end_lnr)) + 1 " Include \n

    exec start_lnr
  endif

  return [start_lnr, start_col, end_lnr, end_col]
endfunction

" Text Objects - map {{{1

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
        let b:elixir_mix_start_col = start_col
        let b:elixir_mix_operator = v:operator
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
      \ :call cursor([line('.'), b:elixir_mix_start_col + 1])<bar>
      \ :unlet b:elixir_mix_operator<bar>
      \ :unlet b:elixir_mix_start_col<cr>

" Text Objects - block {{{1

function! s:textobj_block(inside) abort
  let Skip = {-> s:skip_terms('Tuple\|String\|Comment') || s:is_lambda()}
  let view = winsaveview()

  normal! ^

  let [cursor_origin_lnr, cursor_origin_col] = [line('.'), col('.')]
  let do_pos = searchpos('\<do\>', 'Wc', 0, 0, Skip)

  let func_pos = s:jump_to_function()

  if s:in_range(cursor_origin_lnr, cursor_origin_col, func_pos, do_pos) && do_pos != [0, 0]
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
    let start_lnr = do_pos[0]
  else
    let [start_lnr, start_col] = func_pos
  endif

  let [start_lnr, start_col, end_lnr, end_col] = s:adjust_block_region(a:inside, start_lnr, start_col, end_lnr, end_col)

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

" Text Objects - def {{{1

function! s:textobj_def(keyword, inside, ignore_meta) abort
  let Skip = {-> s:skip_terms('Tuple\|String\|Comment') || s:is_lambda()}
  let view = winsaveview()
  let keyword = '\<\%('.escape(a:keyword, '|').'\)\>'

  normal! ^

  if s:cursor_function_metadata() || s:is_blank(getline('.'))
    call search(keyword, 'Wc', 0, 0, Skip)
  endif

  let [cursor_origin_lnr, cursor_origin_col] = [line('.'), col('.')]
  let func_pos = searchpos(keyword, 'Wcb', 0, 0, Skip)
  let do_pos = searchpos('\<do\>', 'W', 0, 0, Skip)
  let end_pos = searchpairpos('\<do\>', '', '\<end\>', 'Wn', Skip)

  if s:in_range(cursor_origin_lnr, cursor_origin_col, func_pos, end_pos) && do_pos != [0, 0]
    call setpos('.', [0, do_pos[0], do_pos[1], 0])
    let [end_lnr, end_col] = end_pos
  else
    call winrestview(view)
    normal! wb

    let func_pos = searchpos(keyword, 'Wc', 0, 0, Skip)
    let do_pos = searchpos('\<do\>', 'Wc', 0, 0, Skip)
    call setpos('.', [0, do_pos[0], do_pos[1], 0])
    let [end_lnr, end_col] = searchpairpos('\<do\>', '', '\<end\>', 'Wn', Skip)
  endif

  if func_pos == [0, 0]
    return winrestview(view)
  endif

  let start_col = 1

  if a:inside
    let start_lnr = do_pos[0]
  else
    let [start_lnr, start_col] = func_pos
  endif

  call setpos('.', [0, start_lnr, start_col, 0])
  let last_meta_lnr = start_lnr

  let start_col = 0

  if !a:inside && !a:ignore_meta
    if !s:is_blank(getline('.'))
      normal! k^
    endif

    while s:cursor_function_metadata() || s:is_blank(getline('.'))
      " call writefile([s:cursor_synstack_str()], 'foo.vim', 'a')

      if s:cursor_function_metadata()
        let last_meta_lnr = line('.')
      endif

      normal! k^
    endwhile

    let start_lnr = last_meta_lnr
  endif

  let [start_lnr, start_col, end_lnr, end_col] = s:adjust_block_region(a:inside, start_lnr, start_col, end_lnr, end_col)

  let view.lnum = start_lnr
  call s:textobj_select_obj(view, start_lnr, start_col, end_lnr, end_col)
endfunction

" Text Objects - comment {{{1

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

  if a:inside && comment_type ==# 'DocString'
    let start_lnr += 1
    let end_lnr -= 1
    let end_col = len(getline(end_lnr))
  else
    let end_col = len(getline(end_lnr)) + 1
  endif

  let view.lnum = start_lnr
  call s:textobj_select_obj(view, start_lnr, start_col, end_lnr, end_col)
endfunction

" Text Objects - sigil {{{1
fun! V()
  return s:cursor_term()
endfun

function! s:textobj_sigil(inner)
  let Skip = {->
        \ index([
        \   'Sigil',
        \   'MixSigil',
        \   'DelimEscape',
        \   'MixDelimEscape',
        \   'RegexEscapePunctuation',
        \   'MixRegexEscapePunctuation'
        \ ], s:cursor_term()) >= 0}

  let view = winsaveview()
  let regex = '{\|<\|\[\|(\|)\|\/\||\|"\|'''

  let on_modifier = 0
  if s:cursor_term() !~ 'Sigil' && expand('<cWORD>') =~ '\%('.regex.'\)\w\+$'
    normal! b
    if s:cursor_term() =~ 'Sigil'
      let on_modifer = 1
    endif
  endif

  if s:cursor_term() =~ 'Sigil' || on_modifier
    let [start_lnr, start_col] = searchpos('\~', 'Wcb', 0, 0, Skip)
  else
    let [start_lnr, start_col] = searchpos('\~', 'Wc', 0, 0, Skip)
  endif

  let line = getline('.')[col('.') - 1:]
  let open = matchstr(line, regex)

  let close = {
        \   "\/": "\/",
        \   "|": "|",
        \   "'": "'",
        \   '"': '"',
        \   "(": ")",
        \   "[": "]",
        \   "{": "}",
        \   "<": ">"
        \ }[open]

  if a:inner
    call search(open, 'W', 0, 0, Skip)
    exec "normal! ".(len(open))."\<space>"
    let [start_lnr, start_col] = [line('.'), col('.')]
    call search(close, 'W', 0, 0, Skip)
    exec "normal! 1\<left>"
  else
    call search(open, 'W', 0, 0, Skip)
    call search(close, 'W', 0, 0, Skip)

    if len(open) == 3
      normal! ll
    endif

    call search('\a\+', 'We')
  endif

  let [end_lnr, end_col] = [line('.'), col('.')]

  call setpos("'<", [0, start_lnr, start_col, 0])
  call setpos("'>", [0, end_lnr, end_col, 0])

  normal! gv
endfunction

" :ToPipe {{{1

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


" :FromPipe {{{1

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
  return synIDattr(synID(line('.'), col('.'), 0), "name") =~ '\%(String\|Comment\|CharList\|List\|Map\|Tuple\)'
endfunction

function! s:skip_terms(str)
  return synIDattr(synID(line('.'), col('.'), 0), "name") =~ '\%('.a:str.'\)'
endfunction

function! s:reset(pos)
  call setpos('.', a:pos)
  echom "Nothing to pipe"

  return 0
endfunction
" Projections - standard {{{1

function! s:define_projections()
  let name = b:elixir_mix_project.name
  " These projections comes straight from elixir-tools.nvim
  " Thanks, @mhanberg

  let projectionist_heuristics = {
        \   "lib/**/views/*_view.ex": {
        \     "type": "view",
        \     "alternate": "test/{dirname}/views/{basename}_view_test.exs",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View do",
        \       "  use {dirname|camelcase|capitalize}, :view",
        \       "end"
        \     ]
        \   },
        \   "test/**/views/*_view_test.exs": {
        \     "type": "test",
        \     "alternate": "lib/{dirname}/views/{basename}_view.ex",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ViewTest do",
        \       "  use ExUnit.Case, async: true",
        \       "",
        \       "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View",
        \       "end"
        \     ]
        \   },
        \   "lib/**/controllers/*_controller.ex": {
        \     "type": "controller",
        \     "alternate": "test/{dirname}/controllers/{basename}_controller_test.exs",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Controller do",
        \       "  use {dirname|camelcase|capitalize}, :controller",
        \       "end"
        \     ]
        \   },
        \   "test/**/controllers/*_controller_test.exs": {
        \     "type": "test",
        \     "alternate": "lib/{dirname}/controllers/{basename}_controller.ex",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ControllerTest do",
        \       "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
        \       "end"
        \     ]
        \   },
        \   "lib/**/controllers/*_html.ex": {
        \     "type": "html",
        \     "alternate": "test/{dirname}/controllers/{basename}_html_test.exs",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}HTML do",
        \       "  use {dirname|camelcase|capitalize}, :html",
        \       "",
        \       "  embed_templates \"{basename|snakecase}_html/*\"",
        \       "end"
        \     ]
        \   },
        \   "test/**/controllers/*_html_test.exs": {
        \     "type": "test",
        \     "alternate": "lib/{dirname}/controllers/{basename}_html.ex",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}HTMLTest do",
        \       "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
        \       "",
        \       "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}HTML",
        \       "end"
        \     ]
        \   },
        \   "lib/**/controllers/*_json.ex": {
        \     "type": "json",
        \     "alternate": "test/{dirname}/controllers/{basename}_json_test.exs",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}JSON do",
        \       "end"
        \     ]
        \   },
        \   "test/**/controllers/*_json_test.exs": {
        \     "type": "test",
        \     "alternate": "lib/{dirname}/controllers/{basename}_json.ex",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}JSONTest do",
        \       "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
        \       "",
        \       "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}JSON",
        \       "end"
        \     ]
        \   },
        \   "lib/**/components/*.ex": {
        \     "type": "component",
        \     "alternate": "test/{dirname}/components/{basename}_test.exs",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize} do",
        \       "  use Phoenix.Component",
        \       "end"
        \     ]
        \   },
        \   "test/**/components/*_test.exs": {
        \     "type": "test",
        \     "alternate": "lib/{dirname}/components/{basename}.ex",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Test do",
        \       "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
        \       "",
        \       "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}",
        \       "end"
        \     ]
        \   },
        \   "lib/**/live/*_component.ex": {
        \     "type": "livecomponent",
        \     "alternate": "test/{dirname}/live/{basename}_component_test.exs",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Component do",
        \       "  use {dirname|camelcase|capitalize}, :live_component",
        \       "end"
        \     ]
        \   },
        \   "test/**/live/*_component_test.exs": {
        \     "type": "test",
        \     "alternate": "lib/{dirname}/live/{basename}_component.ex",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ComponentTest do",
        \       "  use {dirname|camelcase|capitalize}.ConnCase",
        \       "",
        \       "  import Phoenix.LiveViewTest",
        \       "end"
        \     ]
        \   },
        \   "lib/**/live/*.ex": {
        \     "type": "liveview",
        \     "alternate": "test/{dirname}/live/{basename}_test.exs",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize} do",
        \       "  use {dirname|camelcase|capitalize}, :live_view",
        \       "end"
        \     ]
        \   },
        \   "test/**/live/*_test.exs": {
        \     "type": "test",
        \     "alternate": "lib/{dirname}/live/{basename}.ex",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Test do",
        \       "  use {dirname|camelcase|capitalize}.ConnCase",
        \       "",
        \       "  import Phoenix.LiveViewTest",
        \       "end"
        \     ]
        \   },
        \   "lib/**/channels/*_channel.ex": {
        \     "type": "channel",
        \     "alternate": "test/{dirname}/channels/{basename}_channel_test.exs",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel do",
        \       "  use {dirname|camelcase|capitalize}, :channel",
        \       "end"
        \     ]
        \   },
        \   "test/**/channels/*_channel_test.exs": {
        \     "type": "test",
        \     "alternate": "lib/{dirname}/channels/{basename}_channel.ex",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ChannelTest do",
        \       "  use {dirname|camelcase|capitalize}.ChannelCase, async: true",
        \       "",
        \       "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel",
        \       "end"
        \     ]
        \   },
        \   "test/**/features/*_test.exs": {
        \     "type": "feature",
        \     "template": [
        \       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Test do",
        \       "  use {dirname|camelcase|capitalize}.FeatureCase, async: true",
        \       "end"
        \     ]
        \   },
        \   "lib/*.ex": {
        \     "type": "domain",
        \     "alternate": "test/{}_test.exs",
        \     "template": ["defmodule {camelcase|capitalize|dot} do", "end"],
        \   },
        \   "test/*_test.exs": {
        \     "type": "test",
        \     "alternate": "lib/{}.ex",
        \     "template": [
        \       "defmodule {camelcase|capitalize|dot|elixir_module}Test do",
        \       "  use ExUnit.Case, async: true",
        \       "",
        \       "  alias {camelcase|capitalize|dot|elixir_module}",
        \       "end"
        \     ]
        \   },
        \   "lib/mix/tasks/*.ex": {
        \     "type": "task",
        \     "alternate": "test/mix/tasks/{}_test.exs",
        \     "template": [
        \       "defmodule Mix.Tasks.{camelcase|capitalize|dot|elixir_module} do",
        \       "   use Mix.Task",
        \       "",
        \       "  @shortdoc \"{}\"",
        \       "",
        \       "  @moduledoc \"\"\"",
        \       "  {}",
        \       "  \"\"\"",
        \       "",
        \       "  @impl true",
        \       "  @doc false",
        \       "  def run(argv) do",
        \       "",
        \       "  end",
        \       "end"
        \     ]
        \   },
        \   'mix.exs': {
        \     'type': 'mix',
        \     'alternate': 'mix.lock',
        \     'dispatch': 'mix do deps.unlock --all, deps.update --all'
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
        \   'priv/repo/migrations/*.exs': { 'type': 'migration', 'dispatch': 'mix ecto.migrate' }
        \ }

  if !empty(b:elixir_mix_project.name)
    let projectionist_heuristics['lib/*.ex']['related'] = ["lib/".name.".ex"]

    call extend(projectionist_heuristics, {
        \   'lib/'.name.'_web.ex': {
        \     'type': 'web',
        \   },
        \   'lib/'.name.'_web/router.ex': {
        \     'type': 'router',
        \     'alternate': 'lib/'.name.'_web/endpoint.ex',
        \   },
        \   'lib/'.name.'_web/endpoint.ex': {
        \     'type': 'endpoint',
        \     'alternate': 'lib/'.name.'_web/router.ex'
        \   }
        \ })
  endif


  if g:elixir_mix_projections ==# 'replace'
    let g:projectionist_heuristics['mix.exs'] = projectionist_heuristics
  elseif g:elixir_mix_projections ==# 'merge'
    call extend(g:projectionist_heuristics['mix.exs'], projectionist_heuristics)
  endif
endfunction
