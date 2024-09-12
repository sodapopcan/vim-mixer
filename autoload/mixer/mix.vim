vim9script

import './util.vim'
import './async.vim'
import './cursor.vim'

# AWK command from @mhandberg
const MIX_HELP = "mix help | awk -F ' ' '{printf \"%s\\n\", $2}' | grep -E \"[^-#]\\w+\""
const ENV_SET_SWITCH = '^='
const ENV_ADD_SWITCH = '^+'
const DEFAULT_ENV = 'dev'

g:mixer_async_runners = [
  'Dispatch',
  'Neomake',
  'AsyncRunner',
  'AsyncDo'
]

# PopulateMixTasks {{{1

export def PopulateMixTasks()
  # Clear the current list of tasks
  b:mix_project.tasks = []

  async.Append(MIX_HELP, b:mix_project.tasks)
enddef


# MixCommand {{{1

export def MixCommand(bang: bool, ...rest: list<string>)
  RunMixCommand(bang, '', rest)
enddef

export def MixComplete(A: string, L: string, P: number): list<string>
  final tasks = []

  if exists('b:mix_project')
    extend(tasks, copy(b:mix_project.tasks))
  else
    extend(tasks, systemlist(MIX_HELP))
  endif

  return filter(tasks, (_, v) => v =~ A)
enddef

# DepsCommand {{{1

export def DepsCommand(
    bang: bool,
    mods: string,
    range: number,
    line1: number,
    line2: number,
    ...rest: list<string>
    )
  var [meta, args] = RemoveMixerMeta(rest)

  var cmd: string
  var task_fragment: string

  if len(rest) == 0
    if mods =~ 'hor\|vert'
      cmd = 'split'
    else
      cmd = 'edit'
    endif

    exec mods cmd b:mix_project.root .. "/mix.exs"
    search('defp\=\s*' .. b:mix_project.deps_fun, 'c')
    exec "normal! z\<cr>"

    return
  elseif len(rest) > 0 && args[0] ==# 'add'
    if len(rest) == 1
      util.Error("No dep given.") | return
    endif

    FindDep(args[1])
    return
  elseif len(rest) > 0
    task_fragment = args[0]
    args = args[1 :]
  else
    task_fragment = ""
    args = []
  endif

  if expand('%t') =~ "mix.exs" && getbufinfo(bufnr())[0].changed
    write
  endif

  if range > 0
    for lnr in range(line1, line2)
      call add(args, matchstr(getline(lnr), '\%(\s\+\)\?{:\zs\w\+'))
    endfor
  endif

  args = extend(meta, args)

  var task = join(["deps", task_fragment], ".")

  call RunMixCommand(bang, task, args)
enddef

export def DepsComplete(A: string, L: string, P: number): list<string>
  return b:mix_project.tasks
    -> copy()
    -> filter((_, v) => v =~ '^deps' && v !=# 'deps')
    -> map((_, v) => util.Sub(v, '^deps\.', ''))
    -> filter((_, v) => v =~ A)
enddef

def NewDepDict(dep: string): dict<any>
  return copy({
    "dep": dep,
    "lnr": line("."),
    "output": []
  })
enddef

def FindDep(dep: string)
  echom "Finding deps..."
  var cmd = 'mix hex.info ' .. dep

  g:mixer_deps_add = NewDepDict(dep)

  job_start(["sh", "-c", cmd], {
    "out_cb": function("GatherDepOutput"),
    "exit_cb": function("AppendDep"),
    "mode": "nl"
  })
enddef

def GatherDepOutput(_channel: channel, line: string)
  add(g:mixer_deps_add.output, line)
enddef

def AppendDep(_id: job, _status: number)
  if expand('%:p:t') !=# 'mix.exs'
    util.Error("You switched buffers on me.")

    return
  endif

  var lnr = copy(g:mixer_deps_add.lnr)
  var output = join(g:mixer_deps_add.output, "\n")
  var dep = matchstr(output, "{:" .. g:mixer_deps_add.dep .. ",.*}")

  unlet g:mixer_deps_add

  if empty(dep)
    util.Error("Dependency not found")
    return
  endif

  var line = getline(lnr)
  var cursor_origin = cursor.Pos()
  var search_direction = ''

  if line =~# '\[\s*\]'
    # Just an empty [] or even [           ]
    exec ':' .. lnr .. 'delete _'
    append(lnr - 1, ["[", dep, "]"])
    cursor.Set([lnr, 1])
    normal! 3==
    cursor.Set(cursor_origin)

    return
  endif

  if line =~# '\s*\]'
    append(lnr - 1, [dep])
    cursor.Set([lnr, 1])
    normal! ==
  else
    append(lnr, [dep])
    normal! j^
    normal! ==
  endif

  while cursor.PrevLine() !~ '^\s*\%({\|\[\)'
    normal! k^
  endwhile

  if getline(line('.') - 1) =~# '}$'
    setline(line('.') - 1, getline(line('.') - 1) .. ',')
  endif

  cursor.Set([lnr + 1, 1])

  while cursor.NextLine() !~ '^\s*\%({\|\]\)'
    normal! j^
  endwhile

  if getline(line('.') + 1) =~# '^\s*{'
    setline(lnr + 1, getline(lnr + 1) .. ',')
  endif

  cursor.Set(cursor_origin)

  write
enddef


# Gen Command {{{1
export def GenCommand(bang: bool, ...args: list<string>)
  var tasks = GetGenTasks()

  var task = copy(args[0])

  if !has_key(tasks, task)
    util.Error("No task with that name.")
    return
  endif

  var cmd = 'mix ' .. tasks[task] .. ' ' .. join(args[1 :], ' ')

  # This implementation largely taken from @tpope
  const old_makeprg = &l:makeprg
  const old_errorformat = &l:errorformat
  try
    &l:makeprg = cmd
    &l:errorformat = '%# creating %f,%# injecting %f,%-G%.%#'
    noautocmd make!
  finally
    &l:errorformat = old_errorformat
    &l:makeprg = old_makeprg
  endtry

  if !bang && !empty(getqflist())
    cfirst
  endif
enddef

export def GenComplete(A: string, L: string, P: number): list<string>
  return GetGenTasks()
    -> keys()
    -> sort()
    -> filter((_, v) => v =~ A)
enddef

def GetGenTasks(): dict<string>
  const PackageName = (task) => matchstr(task, '^\l\+')
  var gen_tasks = {}
  var dup_keys = []
  var all_tasks = copy(b:mix_project.tasks)

  for task in filter(all_tasks, (_, v) => v =~ '\.gen\.')
    var task_key = matchstr(task, '\.gen\.\zs.*$')

    if has_key(gen_tasks, task_key) || util.InList(dup_keys, task_key)
      var package_name = PackageName(task)
      var dup_key = copy(task_key)
      task_key = task_key .. "-" .. package_name

      if !util.InList(dup_keys, dup_key)
        var dup_task = gen_tasks[dup_key]
        unlet gen_tasks[dup_key]
        var new_key = dup_key .. "-" .. PackageName(dup_task)
        gen_tasks[new_key] = dup_task
        add(dup_keys, dup_key)
      endif
    endif

    gen_tasks[task_key] = task
  endfor

  return gen_tasks
enddef


# IEx Command {{{1

export def IExCommand(bang: bool, mods: string, ...args: list<string>)
  const arg_str = join(args, ' ')
  var cmd: string

  if bang
    cmd = mods .. "iex "
  elseif exists('b:mix_project') && !bang
    cmd = mods .. "iex -S mix"
  else
    cmd = mods .. "iex"
  endif

  t:mixer_term_bufnr =
    term_start(cmd .. ' ' .. arg_str, {
      term_finish: 'close',
      exit_cb: function('IExExit')
    })
enddef

def IExExit(job: job, status: number)
  try
    unlet t:mixer_term_bufnr
  catch
  endtry
enddef


# Run Mix Command {{{1

def RunMixCommand(bang: bool, cmd: string, args: list<string>)
  final envs = []
  final cmd_args = []

  var run_async = true
  if len(args) > 0 && args[0] ==# '!'
    run_async = false
    extend(cmd_args, args[1 :])
  else
    extend(cmd_args, args)
  endif

  var env_arg = ''

  for arg in copy(cmd_args)
    if arg =~ ENV_ADD_SWITCH
      if empty(envs)
        add(envs, DEFAULT_ENV)
      endif

      env_arg = remove(cmd_args, 0)
      add(envs, util.Sub(env_arg, ENV_ADD_SWITCH, ''))
    elseif arg =~ ENV_SET_SWITCH
      env_arg = remove(cmd_args, 0)
      add(envs, util.Sub(env_arg, ENV_SET_SWITCH, ''))
    else
      break
    endif
  endfor

  if empty(envs)
    add(envs, DEFAULT_ENV)
  endif

  if !empty(cmd)
    insert(cmd_args, cmd, 0)
  endif

  var mix_tasks = []

  var env_pipe: string

  for env in envs
    if env ==# 'dev'
      env_pipe = ''
    else
      env_pipe = 'MIX_ENV=' .. env
    endif

    add(mix_tasks, env_pipe .. ' mix ' .. join(cmd_args, ' '))
  endfor

  const mix_cmd = join(mix_tasks, ' && ')
  var async_cmd = get(g:, 'mixer_async_command', 0)

  if !async_cmd
    for runner in g:mixer_async_runners
      if exists(':' .. runner) == 2
        async_cmd = runner
        break
      endif
    endfor
  endif

  if !empty(async_cmd) && run_async
    if bang
      async_cmd = async_cmd .. '!'
    endif

    exec async_cmd mix_cmd
  else
    exec '!' mix_cmd
  endif
enddef

# This filters out `!` and env args to use them in Mix wrapper functions.
# I should come up with something better than this.
def RemoveMixerMeta(args: list<string>): list<any>
  var local_args = copy(args)
  var meta = []

  for arg in args
    if arg =~ ENV_SET_SWITCH .. '\|' .. ENV_ADD_SWITCH
      call add(meta, arg)
      call remove(local_args, 0)
    else
      break
    endif
  endfor

  return [meta, local_args]
enddef
