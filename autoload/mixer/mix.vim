vim9script

import './util.vim'
import './async.vim'

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
      add(envs, util.Sub(env_pipe, '^+', ''))
    elseif arg =~ ENV_SET_SWITCH
      env_pipe = remove(args, 0)
      add(envs, util.Sub(env_pipe, '^\^', ''))
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

export def PopulateMixTasks()
  # Clear the current list of tasks
  b:mix_project.tasks = []

  async.Append(MIX_HELP, b:mix_project.tasks)
enddef

defcompile
