" Location:     autoload/mixer.vim
" Maintainer:   Andrew Haust <https://andrew.hau.st>

" Variables {{{1

let s:func_call_regex = '\%(\<\%(\u\|:\)[A-Za-z_\.]\+\>\|\<\k\+\>\)\%(\s\|(\)'

" Utility {{{1

function! s:sub(str, pat, rep)
  return substitute(a:str, a:pat, a:rep, '')
endfunction

function! s:includes(list, member)
  return index(a:list, a:member) != -1
endfunction

function! s:file_exists(glob)
  return !empty(glob(a:glob))
endfunction

function! s:matches(str, pat)
  return match(a:str, a:pat) >= 0
endfunction

function! s:is_blank(...)
  if a:0
    return a:1 =~ '^\s*$'
  else
    return getline('.') =~ '^\s*$'
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
function! s:in_range(pos, start, end)
  let [lnr, col] = a:pos
  let [start_lnr, start_col] = a:start
  let [end_lnr, end_col] = a:end

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

" Run a job with a pointer to a list to store the job output in memory. 
" This is currently just used for getting mix tasks on start up.
function! s:async_append(cmd, append_output_to)
  if exists("*job_start")
    call job_start(["sh", "-c", a:cmd], {
          \   "out_cb": function("s:_gather_output", [a:append_output_to]),
          \   "mode": "nl"
          \ })
  elseif exists("*jobstart")
    call jobstart(["sh", "-c", a:mix_help], {
          \   "on_stdout": function("s:_gather_output", [a:append_output_to]),
          \   "mode": "nl"
          \ })
  endif
endfunction

function! s:_gather_output(collector, channel, result)
  call add(a:collector, a:result)
endfunction

function! s:command_exists(cmd)
  return exists(":".a:cmd) == 2
endfunction


" Init: Commands {{{1

function! mixer#init() abort
  if !s:command_exists("Mix")
    command -buffer -bang -complete=customlist,s:MixerMixComplete -nargs=* Mix call s:Mix(<bang>0, <f-args>)
  endif

  let mix_file = findfile("mix.exs", ".;")

  if empty(mix_file)
    return 0
  endif

  call s:init_mix_project(mix_file)

  if !s:command_exists("R")
    command -buffer -nargs=0 R call s:R('edit')
  endif

  if !s:command_exists("RE")
    command -buffer -nargs=0 RE call s:R('edit')
  endif

  if !s:command_exists("RS")
    command -buffer -nargs=0 RS call s:R('split')
  endif

  if !s:command_exists("RV")
    command -buffer -nargs=0 RV call s:R('vsplit')
  endif

  if !s:command_exists("RT")
    command -buffer -nargs=0 RT call s:R('tabedit')
  endif

  if !s:command_exists("Deps")
    command -buffer -complete=customlist,s:MixerDepsComplete -range -bang -nargs=* Deps call s:Deps(<bang>0, <q-mods>, <range>, <line1>, <line2>, <f-args>)
  endif

  if !s:command_exists("Gen")
    command -buffer -complete=customlist,s:MixerGenComplete -bang -nargs=* Gen call s:Gen(<bang>0, <f-args>)
  endif

  if !s:command_exists("Migrate")
    command -buffer -complete=customlist,s:MixerMigrationComplete -count=1 -bang -nargs=* Migrate call s:Migrate(<bang>0, <count>, <f-args>)
  endif
endfunction

function! s:unmapped(map, type)
  return empty(maparg(a:map, a:type))
endfunction


" Init: Mappings {{{1

function mixer#define_mappings()
  let defregex = 'defp\?\|defmacrop\?\|defnp\?'

  exec "vnoremap <silent> <buffer> if :\<c-u>call <sid>textobj_def('".defregex."', 1, 0)\<cr>"
  exec "vnoremap <silent> <buffer> af :\<c-u>call <sid>textobj_def('".defregex."', 0, 0)\<cr>"
  exec "onoremap <silent> <buffer> if :\<c-u>call <sid>textobj_def('".defregex."', 1, 0)\<cr>"
  exec "onoremap <silent> <buffer> af :\<c-u>call <sid>textobj_def('".defregex."', 0, 0)\<cr>"

  exec "vnoremap <silent> <buffer> iF :\<c-u>call <sid>textobj_def('".defregex."', 1, 1)\<cr>"
  exec "vnoremap <silent> <buffer> aF :\<c-u>call <sid>textobj_def('".defregex."', 0, 1)\<cr>"
  exec "onoremap <silent> <buffer> iF :\<c-u>call <sid>textobj_def('".defregex."', 1, 1)\<cr>"
  exec "onoremap <silent> <buffer> aF :\<c-u>call <sid>textobj_def('".defregex."', 0, 1)\<cr>"

  vnoremap <silent> <buffer> iM :<c-u>call <sid>textobj_def('defmodule', 1, 1)<cr>
  vnoremap <silent> <buffer> aM :<c-u>call <sid>textobj_def('defmodule', 0, 1)<cr>
  onoremap <silent> <buffer> iM :<c-u>call <sid>textobj_def('defmodule', 1, 1)<cr>
  onoremap <silent> <buffer> aM :<c-u>call <sid>textobj_def('defmodule', 0, 1)<cr>

  vnoremap <silent> <buffer> iq :<c-u>call <sid>textobj_def('quote', 1, 1)<cr>
  vnoremap <silent> <buffer> aq :<c-u>call <sid>textobj_def('quote', 0, 1)<cr>
  onoremap <silent> <buffer> iq :<c-u>call <sid>textobj_def('quote', 1, 1)<cr>
  onoremap <silent> <buffer> aq :<c-u>call <sid>textobj_def('quote', 0, 1)<cr>

  vnoremap <silent> <buffer> id :<c-u>call <sid>textobj_block(1, 0)<cr>
  vnoremap <silent> <buffer> ad :<c-u>call <sid>textobj_block(0, 0)<cr>
  onoremap <silent> <buffer> id :<c-u>call <sid>textobj_block(1, 0)<cr>
  onoremap <silent> <buffer> ad :<c-u>call <sid>textobj_block(0, 0)<cr>

  vnoremap <silent> <buffer> iD :<c-u>call <sid>textobj_block(1, 0)<cr>
  vnoremap <silent> <buffer> aD :<c-u>call <sid>textobj_block(0, 1)<cr>
  onoremap <silent> <buffer> iD :<c-u>call <sid>textobj_block(1, 0)<cr>
  onoremap <silent> <buffer> aD :<c-u>call <sid>textobj_block(0, 1)<cr>

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

  nnoremap <silent> <buffer> <c-]> :call <sid>find_event()<cr>

  call s:define_argument_mappings()
endfunction

"}}} Jump to event handler/hook {{{1

function! s:find_event()
  let cursor_word = expand('<cWORD>')

  if cursor_word !~ '^phx-'
    exec "normal! \<c-]>"
  endif

  if s:matches(cursor_word, 'phx-.\+=''')
    let char = ''''
  elseif s:matches(cursor_word, 'phx-.\+="')
    let char = '"'
  else
    exec "normal! \<c-]>"
    return
  endif

  let save_i = @i
  exec 'normal! "iyi'.char
  let token = @i
  let @i = save_i

  call searchpos('def handle_event(\%(\%(\s\|\n\)\+\)\?"'.token, 's')
endfunction

" Sideways/SplitJoin integration {{{1

function! s:define_argument_mappings()
  if exists('g:loaded_sideways') && get(g:, 'mixer_enable_textobj_arg')
    if s:unmapped('aa', 'x') && s:unmapped('ia', 'o')
      omap aa <Plug>SidewaysArgumentTextobjA
      xmap aa <Plug>SidewaysArgumentTextobjA
      omap ia <Plug>SidewaysArgumentTextobjI
      xmap ia <Plug>SidewaysArgumentTextobjI
    endif

    if exists('g:loaded_splitjoin') && s:unmapped('<aa', 'n') && s:unmapped('>aa', 'n')
      nnoremap <aa :call <sid>arg_left(0)<cr>
      nnoremap >aa :call <sid>arg_right(0)<cr>
      nnoremap <ia :call <sid>arg_left(1)<cr>
      nnoremap >ia :call <sid>arg_right(1)<cr>
    endif
  endif
endfunction

function! s:arg_left(inner)
  if a:inner
    call sideways#MoveLeft()
  elseif !sideways#MoveLeft({'loop': 0})
    call sj#Split()
  endif
endfunction

function! s:arg_right(inner)
  if a:inner
    call sideways#MoveRight()
  elseif sideways#MoveRight({'loop': 0})
    return
  endif

  let curr_line = getline('.')
  let prev_line = getline(line('.') - 1)
  let next_line = getline(line('.') + 1)
  let pipe_start = '^\%(\s*\)\?|>'

  let on_func = curr_line =~ pipe_start && prev_line !~ pipe_start
  let on_pipe_arg = curr_line !~ pipe_start && next_line =~ pipe_start

  if on_pipe_arg || on_func 
    if on_pipe_arg
      normal! j
    endif

    normal! 0t(
    let arg_pos = [line('.') - 1, col('.') - 1]

    call sj#Join()
    call cursor(arg_pos)
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

function! s:cursor_syn_name(...)
  " return s:sub(synIDattr(synID(line('.'), col('.'), 0), "name"), '^elixir', '')
  if a:0
    let [line, col] = [a:1, a:2]
  else
    let [line, col] = s:get_cursor_pos()
  endif

  let names = map(synstack(line, col), 'synIDattr(v:val,"name")')
  if len(names)
    return s:sub(names[-1], 'elixir', '')
  else
    return ''
  endif
endfunction

function! s:cursor_in_gutter()
  let leading_whitespace_len = len(matchstr(getline('.'), '^\s\+'))

  return col('.') <= leading_whitespace_len
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

  return terms[0] ==# 'elixirMixerLambda'
endfunction

function! s:cursor_on_comment()
  return index(['Comment', 'DocString', 'DocStringDelimiter'], s:cursor_outer_syn_name()) > -1
endfunction

function! s:cursor_on_comment_or_blank_line()
  return s:cursor_on_comment() || s:is_blank()
endfunction

function! s:is_string_or_comment()
  return s:cursor_syn_name() =~ 'String\|Comment\|CharList\|Atom'
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

function! s:get_cursor_pos()
  return [line('.'), col('.')]
endfunction

function! s:get_prev_line() abort
  return getline(line('.') - 1)
endfunction

function! s:get_term(cmd)
  let save_i = @i
  exec 'normal! "i'.a:cmd
  let value = @i
  let @i = save_i

  return value
endfunction

let s:pairs = {
        \   '(': ')',
        \   ')': '(',
        \   '{': '}',
        \   '}': '{',
        \   '[': ']',
        \   ']': '[',
        \ }

function! s:get_pair(delim)
  return get(s:pairs, a:delim, 0)
endfunction

" Syntax helpers - Functions {{{1

function! s:find_do(flags)
  return searchpos('\<do\>:\?', a:flags, 0, 0, {-> s:cursor_syn_name() =~ 'String\|Comment\|CharList'})
endfunction

function! s:paren_in_range(do_pos)
  if expand('<cWORD>') =~ '\<\k\+\>('
    normal! f(
    let open_pos = s:get_cursor_pos()
    let pair_pos = searchpairpos('(', '', ')', 'Wn', {-> s:is_string_or_comment()})
    normal! b

    return s:in_range(a:do_pos, open_pos, pair_pos)
  else
    return 1
  endif
endfunction

function! s:find_do_block_head(do_pos, flags)
  " This is a bit nuts because we want to be able to find user-defined macro
  " calls, not just the builtins.

  " let stop = search('\%(\<end\>\|^\s*$\)', 'Wbn')
  let Skip = {->
        \ expand('<cword>') =~ '\<when\>\|\<in\>\|\<not\>' ||
        \ !s:paren_in_range(a:do_pos) ||
        \ s:cursor_syn_name() =~ 'Operator\|Number\|Atom\|String\|Tuple\|List\|Map\|Struct\|Sigil'
        \ }

  let func_pos = searchpos('\%(>\|=\|\%(\s\+\)\)\s\+\zs\<\k\+\>\s\+\<do\>:\?', 'Wb', line('.'))
  if line('.') == func_pos[0]
    " We're going to do the bone-headed thing here and walk up until we find
    " a non-blank line then see if it ends in a comma.
    normal! k
    while s:is_blank()
      if line('.') == 1 | return | endif
      normal! k
    endwhile

    if getline('.') !~ ',$'
      call cursor(func_pos)

      return func_pos
    endif
  endif

  " '\%(\<end\>\|\%(,$\)\)'
  " let start = '\%(\<end\>\s\+\)\@!\zs'
  let start = ''
  let no_follow = '\%(=\|\~\|<\|>\|\!\|&\||\|+\|\*\|\/\|-\|\<do\>\|\<when\>\|\<not\>\|\<in\>\)\@!'

  return searchpos(start.s:func_call_regex.no_follow, a:flags, 0, 0, Skip)
endfunction

function! s:do_find_end() abort
  call search('(\|{\|\[', 'W', line('.')) " Check if do block is a construct or function call

  if expand('<cWORD>') =~ '\<\k\+\>:'
    " Not a construct or function call
    return search(')\|,\|\n', 'W', 0, 0, {-> s:cursor_syn_name() =~ 'String\|Comment\|Atom\|Sigil\|Number'})
  else
    let open_char = s:cursor_char()
    let close_char = s:get_pair(open_char)

    if searchpair(escape(open_char, '['), '', escape(close_char, ']'), 'W', {-> s:is_string_or_comment()})
      if getline('.')[col('.')] ==# ','
        normal! l
      endif
    endif

    return 1
  endif
endfunction

function! s:get_end_pos()
  while s:cursor_char() =~ '}\|\]'
    normal! h
  endwhile

  return s:get_cursor_pos()
endfunction

function! s:find_end_pos(func_pos, do_pos) abort
  call cursor(a:do_pos)

  let Skip = {-> s:cursor_syn_name() =~ 'String\|Comment' || s:is_lambda_end(a:do_pos)}

  if expand('<cWORD>') ==# 'do:'
    " First we can check if if it's call with parens as that is easy to find the
    " end:
    call cursor(a:func_pos)
    if getline(line('.')) =~ '\#%'.s:func_call_regex.'('
      normal! f(

      return searchpairpos('(', '', ')', 'W', {-> s:is_string_or_comment()})
    else
      call cursor(a:do_pos)
    endif

    while s:do_find_end()
      if s:cursor_char() ==# ','
        normal! w
        if expand('<cWORD>') =~ '\<\k\+\>:'
          continue
        else
          normal! geh

          return s:get_end_pos()
        endif
      elseif s:cursor_char() ==# ')'
        let open_pos = searchpairpos('(', '', ')', 'Wbn', {-> s:is_string_or_comment()})
        if open_pos[0] == a:func_pos[0] && open_pos[1] == a:func_pos[1] - 1
          normal! h
        endif

        return s:get_end_pos()
      else
        return s:get_end_pos()
      endif
    endwhile
  else
    let pos = searchpairpos('\<do\>:\@!', '', '\<end\>', 'W', Skip)
    let pos[1] += 2

    return pos
  end
endfunction

" TODO: Maybe take arity into account.
function! s:find_first_func_head(def_pos) abort
  let func_name = s:get_func_name(a:def_pos)
  while search('def\%(\l\+\)\?\s\+'.func_name, 'Wb') | endwhile

  return s:get_cursor_pos()
endfunction

function! s:find_last_func_head(def_pos) abort
  let func_name = s:get_func_name(a:def_pos)
  while search('def\%(\l\+\)\?\s\+\<'.func_name.'\>', 'W') | endwhile

  return s:get_cursor_pos()
endfunction

function! s:get_func_name(def_pos) abort
  call cursor(a:def_pos)
  normal! W
  let func_name = expand('<cword>')
  normal! ^
  return func_name
endfunction

function! s:is_lambda_end(do_pos)
  if expand('<cword>') ==# 'end'
    return searchpair('\<fn\>', '', '\<end\>', 'Wbn', {-> s:is_string_or_comment()}, a:do_pos[0])
  endif

  return 0
endfunction

function! s:check_for_meta(known_annotations)
  let word = expand('<cword>')
  let WORD = expand('<cWORD>')

  return
        \ s:cursor_synstack_str() =~ 'Comment\|DocString' ||
        \ word =~ a:known_annotations ||
        \ WORD =~ a:known_annotations
endfunction

" Mix: Project {{{1

function! s:init_mix_project(mix_file) abort
  let mix_file = a:mix_file

  if !exists("g:mix_projects")
    let g:mix_projects = {}
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
    let deps_fun = matchstr(contents, 'def project\%(()\)\?\_.*deps:\s\+\zs\w\+\ze\%(()\)\?,')
  catch
    let project_name = ""
    let deps_fun = ""
  endtry

  if !has_key(g:mix_projects, project_root)
    let g:mix_projects[project_root] = {
          \   "root": project_root,
          \   "name": project_name,
          \   "alias": s:to_elixir_alias(project_name),
          \   "deps_fun": deps_fun,
          \   "tasks": []
          \ }

    let b:mix_project = g:mix_projects[project_root]

    call s:populate_mix_tasks()
  else
    let b:mix_project = g:mix_projects[project_root]
  endif

  autocmd! DirChanged * let b:mix_project.root = s:sub(findfile("mix.exs", ".;"), 'mix.exs$', '')

  if exists('g:loaded_matchit')
    if !exists('s:html_match_words')
      " This is ripped straight from matchit since I don't know of a way to see
      " what is globally defined.
      let s:html_match_words = '<!--:-->,<:>,<\@<=[ou]l\>[^>]*\%(>\|$\):<\@<=li\>:<\@<=/[ou]l>,<\@<=dl\>[^>]*\%(>\|$\):<\@<=d[td]\>:<\@<=/dl>,<\@<=\([^/!][^ \t>]*\)[^>]*\%(>\|$\):<\@<=/\1>'
    endif

    function! s:do_match_words()
      if exists('b:match_words') && !exists('b:elixir_match_words')
        let b:elixir_match_words = b:match_words
      endif

      if !exists('b:elixir_match_words') | return | endif

      if s:cursor_outer_syn_name() =~ 'Heex\|Surface'
        let b:match_words = s:html_match_words
      else
        let b:match_words = b:elixir_match_words
      endif
    endfunction

    autocmd! CursorMoved *.ex call s:do_match_words()
  endif

  let g:mix_projections = get(g:, "mix_projections", "replace")

  if g:mix_projections !=# "disable"
    call s:define_projections()
  endif
endfunction

" Mix: Tasks {{{1

function! s:populate_mix_tasks()
  " Awk is from @mhandberg
  let mix_help = "mix help | awk -F ' ' '{printf \"%s\\n\", $2}' | grep -E \"[^-#]\\w+\""

  call s:async_append(mix_help, b:mix_project.tasks)
endfunction

function! s:get_mix_tasks()
  " Awk is from @mhandberg
  let mix_help = "mix help | awk -F ' ' '{printf \"%s\\n\", $2}' | grep -E \"[^-#]\\w+\""

  return split(system(mix_help), '\n')
endfunction

function! s:gather_mix_tasks(_channel, result)
  let g:mixer_tasks = get(g:, "mixer_tasks", [])
  call add(g:mixer_tasks, a:result)
endfunction

" Mix: helpers {{{1

function! s:run_mix_command(bang, cmd, args) abort
  let envs = []
  let default_env = 'dev'

  let args = copy(a:args)

  let async = 1
  if len(args) && args[0] ==# "!"
    let async = 0
    let args = args[1:]
  end

  let rest_args = copy(args)

  for arg in rest_args
    if arg =~ '^+'
      if empty(envs)
        call add(envs, default_env)
      endif

      let env = remove(args, 0)
      call add(envs, s:sub(env, '^+', ''))
    elseif arg =~ '^-'
      let env = remove(args, 0)
      call add(envs, s:sub(env, '^-', ''))
    else
      break
    endif
  endfor

  if empty(envs)
    call add(envs, default_env)
  endif

  if a:cmd != ""
    call insert(args, a:cmd, 0)
  endif

  let mix_tasks = []

  for env in envs
    call add(mix_tasks, "MIX_ENV=".env." mix ".join(args, " "))
  endfor

  let mix_cmd = join(mix_tasks, " && ")
  let async_cmd = g:mixer_async_command

  if !async_cmd
    for runner in g:async_runners
      if s:command_exists(runner)
        let async_cmd = runner
        break
      endif
    endfor
  endif

  if !empty(async_cmd) && async
    if a:bang
      let async_cmd = async_cmd.'!'
    endif

    exec async_cmd mix_cmd
  else
    exec "!" mix_cmd
  endif
endfunction

" This filters out `!` and env args to use them in Mix wrapper functions.
" I should come up with something better than this.
function! s:remove_mixer_meta(args)
  let args = copy(a:args)
  let meta = []

  for arg in a:args
    if arg =~ '^!\|+\|-'
      call add(meta, arg)
      call remove(args, 0)
    else
      break
    endif
  endfor

  return [meta, args]
endfunction


" Mix: :Mix {{{1

function! s:Mix(bang, ...) abort
  call s:run_mix_command(a:bang, "", a:000)
endfunction

function! s:MixerMixComplete(A, L, P) abort
  if exists('b:mix_project')
    let tasks = copy(b:mix_project.tasks)
  else
    let tasks = s:get_mix_tasks()
  endif

  return filter(tasks, {-> v:val =~ a:A})
endfunction

" Mix: :Deps {{{1

function! s:Deps(bang, mods, range, line1, line2, ...) abort
  let [meta, args] = s:remove_mixer_meta(a:000)

  if !a:0
    if a:mods =~ 'hor\|vert'
      let cmd = 'split'
    else
      let cmd = 'edit'
    endif

    exec a:mods cmd b:mix_project.root."/"."mix.exs"
    call search('defp\?\s\+'.b:mix_project.deps_fun, 'c')
    exec "normal! z\<cr>"

    return
  elseif a:0 && args[0] ==# 'add'
    if a:0 == 1
      echom "What do you want me to add?" | return
    endif

    return s:find_dep(args[1])
  elseif a:0
    let task_fragment = args[0]
    let args = args[1:]
  else
    let task_fragment = ""
    let args = []
  endif

  if expand('%t') =~ "mix.exs" && getbufinfo(bufnr())[0].changed
    write
  endif

  if a:range > 0
    for lnr in range(a:line1, a:line2)
      call add(args, matchstr(getline(lnr), '\%(\s\+\)\?{:\zs\w\+'))
    endfor
  endif

  let args = extend(meta, args)

  let task = join(["deps", task_fragment], ".")

  call s:run_mix_command(a:bang, task, args)
endfunction

function! s:find_dep(dep) abort
  let cmd = 'mix hex.info '.a:dep

  let g:mixer_deps_add = {
        \   "dep": a:dep,
        \   "lnr": line("."),
        \   "output": []
        \ }

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
  call add(g:mixer_deps_add.output, a:line)
endfunction

function! s:append_dep(_id, _status) abort
  let output = join(g:mixer_deps_add.output, "\n")
  let dep = matchstr(output, "{:".g:mixer_deps_add.dep.",.*}")

  call search('\]')

  call append(g:mixer_deps_add.lnr, [dep])

  if s:matches(getline(g:mixer_deps_add.lnr), "\]$")
    exec "normal! kA,\<esc>j^"
  else
    exec "normal! A,\<esc>^"
  endif

  unlet g:mixer_deps_add

  write
endfunction

function! s:MixerDepsComplete(A, L, P)
  let deps_tasks = filter(copy(b:mix_project.tasks), {-> v:val =~ '^deps' && v:val !=# 'deps'})
  let bare_tasks = map(deps_tasks, {-> s:sub(v:val, '^deps\.', '')})
  let bare_tasks = filter(bare_tasks, {-> v:val =~ a:A})

  return bare_tasks
endfunction

" Mix: :Gen {{{1

function! s:Gen(bang, ...) abort
  let tasks = s:get_gen_tasks()
  let [meta, args] = s:remove_mixer_meta(a:000)

  let task = args[0]

  if !has_key(tasks, task)
    echom "No task with that name" | return
  endif

  call s:run_mix_command(a:bang, tasks[task], extend(meta, args[1:]))
endfunction

function! s:MixerGenComplete(A, L, P) abort
  let tasks = keys(s:get_gen_tasks())
  let tasks = sort(tasks)
  let tasks = filter(tasks, {-> v:val =~ a:A})

  return tasks
endfunction

function! s:get_gen_tasks() abort
  let PackageName = {task -> matchstr(task, '^\l\+')}
  let gen_tasks = {}
  let dup_keys = []
  let all_tasks = copy(b:mix_project.tasks)

  for task in filter(all_tasks, {-> v:val =~ '\.gen\.'})
    let task_key = matchstr(task, '\.gen\.\zs.*$')

    if has_key(gen_tasks, task_key) || s:includes(dup_keys, task_key)
      let package_name = PackageName(task)
      let dup_key = task_key
      let task_key = task_key."-".package_name

      if !s:includes(dup_keys, dup_key)
        let dup_task = gen_tasks[dup_key]
        unlet gen_tasks[dup_key]
        let new_key = dup_key."-".PackageName(dup_task)
        let gen_tasks[new_key] = dup_task
        call add(dup_keys, dup_key)
      endif
    endif

    let gen_tasks[task_key] = task
  endfor

  return gen_tasks
endfunction


" :Migrate {{{1

function! s:Migrate(bang, count, ...) abort
  let [meta, args] = s:remove_mixer_meta(a:000)

  echom a:count
endfunction

let s:migrate_opts = [
      \   "--all",
      \   "--log-migrations-sql",
      \   "--log-migrator-sql",
      \   "--log-level",
      \   "--migrations-path",
      \   "--no-compile",
      \   "--no-deps-check",
      \   "--pool-size",
      \   "--prefix",
      \   "--quiet",
      \   "--repo",
      \   "--step",
      \   "--strict-version-order",
      \   "--to",
      \   "--to-exclusive",
      \   "-r",
      \   "-n"
      \ ]

function! s:MixerMigrationComplete(A, L, P) abort
  if a:L =~ "-"
    let opts = copy(s:migrate_opts)

    return filter(opts, {-> v:val =~ a:A})
  endif

  let prefix = "/priv/repo/migrations"
  let completions = glob(b:mix_project.root.prefix."/*")
  let completions = split(completions, '\n')
  let completions = map(completions, {-> s:sub(v:val, '^\.'.escape(prefix, '/').'\/', '')})
  let completions = map(completions, {-> s:sub(v:val, '\.exs$', '')})
  let completions = filter(completions, {-> v:val =~ a:A})

  return completions
endfunction

" Phoenix: :R {{{1

function!  s:has_render() abort
  return  search('^\s\+def render(', 'wn')
endfunction

function!  s:in_render() abort
  let Skip = {-> s:cursor_outer_syn_name() =~ 'Map\|List\|String\|Comment\|Atom\|Variable'}
  let view = winsaveview()

  if !sea rch('def render(', 'Wb', 0, 0, Skip)
    return 0
  end

  let start_pos = s:get_cursor_pos()

  call search('\<do\>', 'W', 0, 0, Skip)

  call searchpair('\<do\>', '', '\<end\>', 'W', Skip)
  let end_pos = s:get_cursor_pos()

  call winrestview(view)

  return s:in_range(s:get_cursor_pos(), start_pos, end_pos)
endfunction

function! s:R(type) abort
  if s:has_render()
    if s:in_render()
      let b:tpl_lnr = line('.')

      if b:impl_lnr
        exec b:impl_lnr
      else
        call search('^\s\+def mount(')
      endif
    else
      let b:impl_lnr = line('.')

      if b:tpl_lnr
        exec b:tpl_lnr
      else
        call search('^\s\+def render(')
      endif
    endif
  else
    if &ft ==# 'elixir'
      let basename = s:sub(expand("%:p"), '\.ex$', '.html.heex')
    else
      let basename = s:sub(expand("%:p"), '\.html.heex$', '.ex')
    endif

    if !empty(glob(basename))
      exec a:type basename
    endif
  endif
endfunction


" Text Objects: Helpers {{{1

function! s:textobj_select_obj(view, start_pos, end_pos)
  let [start_lnr, start_col] = a:start_pos
  let [end_lnr, end_col] = a:end_pos

  let g:mixer_view = a:view

  if v:operator ==# 'c'
    unlet g:mixer_view.lnum
    unlet g:mixer_view.col
  endif

  call setpos("'<", [0, start_lnr, start_col, 0])
  call setpos("'>", [0, end_lnr, end_col, 0])

  normal! gv

  if v:operator ==# 'c'
    call feedkeys("\<c-r>=MixerRestoreViewInsert()\<cr>")
  else
    call feedkeys("\<Plug>(MixerRestorView)")
  endif
endfunction

function! MixerRestoreViewInsert() abort
  call winrestview(g:mixer_view)
  unlet g:mixer_view

  return ""
endfunction

nnoremap <silent> <Plug>(MixerRestorView)
      \ :call winrestview(g:mixer_view)<bar>
      \ :unlet g:mixer_view<bar>
      \ :normal! ==^<cr>

function! s:adjust_whitespace(start_pos)
  let [start_lnr, start_col] = a:start_pos

  let start_line = getline(start_lnr)
  let prev_blank = s:is_blank(getline(start_lnr - 1))
  if start_col > 2
    let offset = start_col - 2
  else
    let offset = 0
  endif
  let empty_gutter = start_line[0:offset] =~ '^\s*$'

  if start_lnr > 1 && prev_blank && empty_gutter
    let start_lnr -= 1
    let start_col = 1
  endif

  return [start_lnr, start_col]
endfunction

function! s:adjust_block_region(inner, leave_end_col, start_pos, end_pos) abort
  if v:operator ==# 'c' && !a:inner
    " We want a blank line left for insert mode so don't adjust anything
    return [a:start_pos, a:end_pos]
  endif

  let [start_lnr, start_col] = a:start_pos
  let [end_lnr, end_col] = a:end_pos

  if a:inner
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
    let [start_lnr, start_col] = s:adjust_whitespace([start_lnr, start_col])

    if start_col == 0
      let start_col = 1
    endif

    if !a:leave_end_col
      let end_col = len(getline(end_lnr)) + 1 " Include \n
    endif

    exec start_lnr
  endif

  return [[start_lnr, start_col], [end_lnr, end_col]]
endfunction


" Text Objects: block {{{1

function! s:textobj_block(inner, include_meta) abort
  let view = winsaveview()

  " First check if we are between a function call and a `do`
  let origin = s:get_cursor_pos()
  let do_pos = s:find_do('Wc')

  let func_pos = s:find_do_block_head(do_pos, 'Wb')

  if s:in_range(origin, func_pos, do_pos)
    let end_pos = s:find_end_pos(func_pos, do_pos)
  else
    call cursor(origin)

    let do_pos = s:find_do('Wb')

    if do_pos == [0, 0]
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

  if func_pos == [0, 0] | return winrestview(view) | endif

  if a:inner
    let start_pos = copy(do_pos)
    let start_pos[1] = 1
  else
    let start_pos = func_pos
  endif

  call cursor(do_pos)
  let do = expand('<cWORD>')

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

  if a:inner && do ==# 'do:'
    " Clear `do:` When switching to insert, leaving a space after it.
    let start_pos[1] = do_pos[1] + (v:operator ==# 'c' ? 4 : 3)
  else
    let [start_pos, end_pos] = s:adjust_block_region(a:inner, do ==# 'do:', start_pos, end_pos)
  endif

  let view.lnum = start_pos[0]

  call s:textobj_select_obj(view, start_pos, end_pos)
endfunction


" Text Objects: def {{{1

function! s:textobj_def(keyword, inner, include_annotations) abort
  let known_annotations = '@doc\>\|@spec\>\|@tag\>\|@requirements\>\|\<attr\>\|\<slot\>'
  let user_annotations = get(g:, 'mixer_known_annotations')

  if user_annotations
    let known_annotations = join([known_annotations, user_annotations], '\|')
  endif

  let Skip = {-> s:cursor_syn_name() =~ 'String\|Comment'}
  let view = winsaveview()
  let keyword = '\<\%('.escape(a:keyword, '|').'\)\>'

  normal! ^

  let cursor_origin = s:get_cursor_pos()

  if s:check_for_meta(known_annotations)
    call search(keyword, 'W', 0, 0, Skip)
  endif

  let def_pos = searchpos(keyword, 'Wcb', 0, 0, Skip)
  let do_pos = s:find_do('W')
  let end_pos = s:find_end_pos(def_pos, do_pos)

  if !s:in_range(cursor_origin, def_pos, end_pos) || do_pos == [0, 0]
    call winrestview(view)
    normal! wb

    let def_pos = searchpos(keyword, 'Wc', 0, 0, Skip)
  endif

  if def_pos == [0, 0] | return winrestview(view) | endif

  if !a:inner && a:include_annotations
    let def_pos = s:find_first_func_head(def_pos)
    let do_pos = s:find_do('Wc')
  endif

  call cursor(do_pos)

  let first_head_has_keyword_do = expand('<cWORD>') ==# 'do:'

  if !a:inner && a:include_annotations
    call s:find_last_func_head(def_pos)
  endif

  let last_func_do_pos = s:find_do('Wc')

  let start_pos = def_pos
  let end_pos = s:find_end_pos(def_pos, last_func_do_pos)

  call cursor(def_pos)

  " Look for the meta
  if !a:inner && a:include_annotations
    if !s:is_blank()
      normal! k^
    endif

    let stopline = max([1, search('\<end\>', 'Wbn')])

    call search('\s*$', 'Wb', stopline, 0, {-> s:is_string_or_comment()})

    while search(known_annotations, 'Wb', stopline) | endwhile

    let start_pos = s:get_cursor_pos()
  endif

  if a:inner
    let start_pos = do_pos
    let start_pos[1] = 1
  endif

  if a:inner && first_head_has_keyword_do
    " Clear `do:` When switching to insert, leave a space after it otherwise do not.
    let start_pos[1] = do_pos[1] + (v:operator ==# 'c' ? 4 : 3)
  else
    let [start_pos, end_pos] = s:adjust_block_region(a:inner, 0, start_pos, end_pos)
  endif

  let view.lnum = start_pos[0]
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
  let Skip = {->
        \ index([
        \   'Sigil',
        \   'MixSigil',
        \   'DelimEscape',
        \   'MixDelimEscape',
        \   'RegexEscapePunctuation',
        \   'MixRegexEscapePunctuation'
        \ ], s:cursor_syn_name()) >= 0}

  let view = winsaveview()
  let regex = '{\|<\|\[\|(\|)\|\/\||\|"\|'''

  let on_modifier = 0

  if s:cursor_syn_name() !~ 'Sigil' && expand('<cWORD>') =~ '\%('.regex.'\)\w\+$'
    normal! b
    if s:cursor_syn_name() =~ 'Sigil'
      let on_modifer = 1
    endif
  endif

  if s:cursor_syn_name() =~ 'Sigil' || on_modifier
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
        \   "\"": "\"",
        \   "(": ")",
        \   "[": "]",
        \   "{": "}",
        \   "<": ">"
        \ }[open]

  if a:inner
    call search(open, 'W', 0, 0, Skip)
    exec "normal! ".(len(open))."\<space>"
    let [start_lnr, start_col] = s:get_cursor_pos()
    call search(escape(close, '"'), 'W', 0, 0, Skip)
    exec "normal! 1\<left>"
  else
    call search(open, 'W', 0, 0, Skip)
    call search(escape(close, '"'), 'W', 0, 0, Skip)

    if len(open) == 3
      normal! ll
    endif

    call search('\a\+', 'We')
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

" Projections {{{1

function! s:define_projections()
  if filereadable(b:mix_project.root."/".".projections.json")
    return
  endif

  let name = b:mix_project.name
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

  if !empty(b:mix_project.name)
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


  if g:mix_projections ==# 'replace'
    let g:projectionist_heuristics['mix.exs'] = projectionist_heuristics
  elseif g:mix_projections ==# 'merge'
    call extend(g:projectionist_heuristics['mix.exs'], projectionist_heuristics)
  endif
endfunction
