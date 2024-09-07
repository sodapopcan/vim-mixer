vim9script

import './util.vim'
import './async.vim'
import './cursor.vim'

# AWK command from @mhandberg
const MIX_HELP = "mix help | awk -F ' ' '{printf \"%s\\n\", $2}' | grep -E \"[^-#]\\w+\""
const ENV_ADD_SWITCH = '^+'
const ENV_SET_SWITCH = '^\^'

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

export def MixCommand(bang: bool, ...rest: list<string>): void
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

export def DepsCommand(
    bang: bool,
    mods: string,
    range: number,
    line1: number,
    line2: number,
    ...rest: list<string>
    ): void
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
    search('defp\?\s\+' .. b:mix_project.deps_fun, 'c')
    exec "normal! z\<cr>"

    return
  elseif len(rest) > 0 && args[0] ==# 'add'
    if len(rest) == 1
      echom "What do you want me to add?" | return
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

# DepsCommand {{{1

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

def FindDep(dep: string): void
  echom "Finding deps..."
  var cmd = 'mix hex.info ' .. dep

  g:mixer_deps_add = NewDepDict(dep)

  job_start(["sh", "-c", cmd], {
    "out_cb": function("GatherDepOutput"),
    "exit_cb": function("AppendDep"),
    "mode": "nl"
  })
enddef

def GatherDepOutput(_channel: channel, line: string): void
  add(g:mixer_deps_add.output, line)
enddef

def AppendDep(_id: job, _status: number): void
  if expand('%:p:t') !=# 'mix.exs'
    echom "You switched buffers on me."

    return
  endif

  var lnr = copy(g:mixer_deps_add.lnr)
  var output = join(g:mixer_deps_add.output, "\n")
  var dep = matchstr(output, "{:" .. g:mixer_deps_add.dep .. ",.*}")

  unlet g:mixer_deps_add

  if empty(dep)
    echom "Dependency not found" | return
  endif

  var line = getline(lnr)
  var cursor_origin = cursor.Pos()
  var search_direction = ''

  if line =~# '\[\s*\]'
    # Just an empty [] or even [           ]
    exec lnr .. "delete_"
    append(lnr - 1, ["[", dep, "]"])
    cursor.Set(lnr, 1)
    normal! 3==
    cursor.Set(cursor_origin)

    return
  endif

  if line =~# '\]$'
    searchpair('\[', '', '\]', 'Wb', () => cursor.OnStringOrComment())
  endif

  if line =~# '\[$\|\%( \+\)\|\%( \+#\)\|^\s*$'
    # An empty [] but on different lines
    normal! j^

    while cursor.IsBlank() || cursor.SynName() =~# 'Comment'
      normal! j^
    endwhile

    search_direction = 'down'
  elseif line =~# '\]$\|\%( \+\)\|\%( \+#\)'
    # Same thing but look down.  This is a very bone-headed way to do this.
    # Refactor this.
    normal! k^

    while cursor.IsBlank() || cursor.SynName() =~# 'Comment'
      normal! k^
    endwhile

    search_direction = 'up'
  endif

  var checked_lnr = line('.')
  var checked_line = getline('.')

  if checked_line =~# '\]$'
    # empty [] on different lines
    search('\[', 'Wb', 0, 0, () => cursor.OnStringOrComment())
    append(line('.'), [dep])
    normal! j==k
  elseif checked_line =~# '\[$'
    append(line('.'), [dep])
    normal! j==k
  elseif checked_line =~# '}$'
    setline(line('.'), checked_line .. ',')
    append(checked_lnr, [dep])
    normal! j==k
  elseif checked_line =~# '},\?$'
    if checked_line =~# '}$'
      setline(checked_lnr, checked_line .. ',')
    endif

    if search_direction ==# 'down' && getline(checked_lnr - 1) =~ '\%(\s\+\)\?#'
      # Add under comment
      checked_lnr = line('.') - 1
    endif

    append(checked_lnr, [dep])

    cursor.Set(checked_lnr + 1, 1)
    normal! ==

    cursor.Set(cursor_origin)
  endif

  write
enddef


# Gen Command {{{1

export def GenCommand(bang: bool, ...args: list<string>): void
  var tasks = GetGenTasks()
  var [meta, args] = RemoveMixerMeta(args)

  var task = copy(args[0])

  if !has_key(tasks, task)
    echom "No task with that name"
    return
  endif

  call RunMixCommand(bang, tasks[task], extend(meta, args[1 :]))
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


# Console Command {{{1

export def ConsoleCommand(bang: bool, mods: string): void
  if bang
    exec mods .. " term ++close iex"
  elseif exists('b:mix_project') && !bang
    exec mods .. " term ++close iex -S mix"
  else
    exec mods .. " term ++close iex"
  endif
enddef


# Run Mix Command {{{1

def RunMixCommand(bang: bool, cmd: string, args: list<string>): void
  var envs = []
  final targs = []
  const default_env = 'dev'


  var run_async = true
  if len(args) && args[0] ==# '!'
    run_async = false
    extend(targs, args[1 :])
  else
    extend(targs, args)
  endif

  const rest_args = copy(targs)
  var env_pipe = ''

  for arg in rest_args
    if arg =~ ENV_ADD_SWITCH
      if empty(envs)
        add(envs, default_env)
      endif

      env_pipe = remove(args, 0)
      add(envs, util.Sub(env_pipe, ENV_ADD_SWITCH, ''))
    elseif arg =~ ENV_SET_SWITCH
      env_pipe = remove(args, 0)
      add(envs, util.Sub(env_pipe, ENV_SET_SWITCH, ''))
    else
      break
    endif
  endfor

  if empty(envs)
    add(envs, default_env)
  endif

  if !empty(cmd)
    insert(args, cmd, 0)
  endif

  var mix_tasks = []

  for env in envs
    if env ==# 'dev'
      env_pipe = ''
    else
      env_pipe = 'MIX_ENV=' .. env_pipe
    endif

    add(mix_tasks, env_pipe .. ' mix ' .. join(args, ' '))
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
    if arg =~ '^!\|+\|-'
      call add(meta, arg)
      call remove(local_args, 0)
    else
      break
    endif
  endfor

  return [meta, local_args]
enddef
