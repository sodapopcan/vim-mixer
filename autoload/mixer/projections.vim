vim9script

import autoload "./util.vim"

export def Detect()
  if exists('b:projectionist_file')
    return
  endif

  const mix_project = get(b:, 'mix_project', {})

  if empty(mix_project)
    return
  endif

  const root = mix_project.root

  if !filereadable(root .. '/mix.exs')
    return
  endif

  var projections: dict<dict<any>>

  const contents = join(readfile(root .. '/mix.exs'), '\n')
  const project_name = matchstr(contents, 'def project\_.*app:\s\+:\zs\k\+\ze')

  var globs = util.Glob(root .. '/lib/*')->map((_, f) => fnamemodify(f, ':t'))
  var files = globs->copy()->filter((_, g) => g =~ '\.ex')
  var dirs = globs->copy()->filter((_, g) => g !~ '\.ex')

  projections = {
    'mix.exs': {
      type: 'mix',
      alternate: 'mix.lock',
      dispatch: 'mix deps.get'
    },
    'mix.lock': {
      type: 'lock',
      alternate: 'mix.exs'
    },
    'lib/mix/*.ex': {
      type: 'mix'
    },
    'test/*_test.exs': {
      type: 'test',
      alternate: 'lib/{}.ex',
      dispatch: 'mix test'
    },
    'config/config.exs': {
      type: 'init'
    },
    'config/*.exs': {
      type: 'init',
      alternate: 'config/config.exs'
    },
    'lib/mix/tasks/*.ex': {
      type: 'task',
      template: [
        'defmodule Mix.Task.{camelcase|capitalize|dot} do',
        '  use Mix.Task',
        '',
        '  @shortdoc "Short description"',
        '',
        '  @impl true',
        '  def run([]) do',
        '',
        '  end',
        'end'
      ]
    }
  }

  var web_dir = dirs->copy()->filter((_, d) => d =~ 'web$')

  if len(web_dir) == 1
    web_dir = web_dir[0]

    const web_alias = util.ToElixirAlias(web_dir)
    const web_globs = util.Glob(root .. '/lib/**/*')

    var live_defmodule: string

    if match(web_globs, '_live\.ex') >= 0
      live_defmodule = 'defmodule ' .. web_alias .. '.{basename|camelcase|capitalize}Live do'
    else
      live_defmodule = 'defmodule ' .. web_alias .. '.{basename|camelcase|capitalize} do'
    endif

    projections['lib/' .. web_dir .. '/live/*.ex'] = {
      type: 'live',
      alternate: 'test/' .. web_dir .. '/live/{}_test.exs',
      template: [
        live_defmodule,
        '  use ' .. web_alias  .. ', :live_view',
        '',
        '  @impl true',
        '  def render(assigns) do',
        '    ~H"""',
        '',
        '    """',
        '  end',
        'end'
      ]
    }

    projections['lib/' .. web_dir .. '/controllers/*_controller.ex'] = {
      type: 'controller',
      alternate: 'test/' .. web_dir .. '/controllers/{}_controller_test.exs'
    }
  endif

  for file in files
    var type = util.Sub(file, '^' .. project_name .. '_', '')->util.Sub('\.ex$', '')

    if type == project_name
      type = 'domain'
    endif

    const path = util.Sub(file, '\.ex$', '')

    projections['lib/' .. path .. '.ex'] = {
      type: type,
      alternate: 'test/' .. path .. '_test.exs'
    }
  endfor

  for dir in dirs
    var type = util.Sub(dir, '^' .. project_name .. '_', '')

    if type == project_name
      type = 'domain'
    endif

    projections['lib/' .. dir .. '/*.ex'] = {
      type: type,
      alternate: 'test/' .. dir .. '/{}_test.exs'
    }
  endfor

  projectionist#append(root, projections)
enddef
