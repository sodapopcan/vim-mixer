vim9script

import './util.vim'

export def Mix(bang: bool, ...rest: list<string>): void
  RunMixCommand(bang, "", rest)
enddef

export def MixComplete(A: string, L: string, P: number): list<string>
  var tasks: list<string>

  if exists('b:mix_project')
    tasks = copy(b:mix_project.tasks)
  else
    tasks = ["hi"]
  endif

  return filter(tasks, (_, v) => v =~ A)
enddef

export def RunMixCommand(bang: bool, cmd: string, args: list<string>): void
  var envs = []
  const default_env = 'dev'

  var async = 1
  if len(args) && args[0] ==# "!"
    var async = 0
    var args = args[1:]
  endif

  var rest_args = copy(args)

  for arg in rest_args
    if arg =~ '^+'
      if empty(envs)
        call add(envs, default_env)
      endif

      var env = remove(args, 0)
      call add(envs, util.Sub(env, '^+', ''))
    elseif arg =~ '^\^'
      var env = remove(args, 0)
      call add(envs, util.Sub(env, '^\^', ''))
    else
      break
    endif
  endfor

  if empty(envs)
    call add(envs, default_env)
  endif

  if cmd != ""
    call insert(args, cmd, 0)
  endif

  var mix_tasks = []

  for env in envs
    if env ==# 'dev'
      var env = ""
    else
      var env = "MIX_ENV=".env
    endif

    call add(mix_tasks, env." mix ".join(args, " "))
  endfor

  var mix_cmd = join(mix_tasks, " && ")

  var async_cmd = get(g:, 'mixer_async_command', 0)

  if !async_cmd
    for runner in g:async_runners
      if exists(runner) == 2
        var async_cmd = runner
        break
      endif
    endfor
  endif

  if !empty(async_cmd) && async
    if bang
      var async_cmd = async_cmd.'!'
    endif

    exec async_cmd mix_cmd
  else
    exec "!" mix_cmd
  endif
enddef
