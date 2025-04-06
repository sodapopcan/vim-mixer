vim9script

import autoload "./util.vim"

export def Detect()
  if exists('b:projectionist_file')
    return
  endif

  var project_name: string

  const project = get(b:, 'mix_project', {})

  if empty(project)
    return
  endif

  project_name = project.name

  var projections: dict<dict<any>>

  const root = b:mix_project.root
  const contents = join(readfile(root .. '/mix.exs'), '\n')
  project_name = matchstr(contents, 'def project\_.*app:\s\+:\zs\k\+\ze')

  var globs = util.Glob(root .. '/lib/*')-> map((_, f) => fnamemodify(f, ':t'))
  var files = globs->copy()->filter((_, g) => g =~ '\.ex')
  var dirs = globs->copy()->filter((_, g) => g !~ '\.ex')

  projections['mix.exs'] = {
    type: 'mix',
    alternate: 'mix.lock',
    dispatch: 'mix deps.get'
  }

  projections['mix.lock'] = {
    type: 'lock',
    alternate: 'mix.exs'
  }

  projections['lib/mix/*.ex'] = {
    type: 'mix'
  }

  projections['test/*_test.exs'] = {
    type: 'test',
    alternate: 'lib/{}.ex',
    dispatch: 'mix test'
  }

  projections['config/config.exs'] = {
    type: 'init'
  }

  projections['config/*.exs'] = {
    type: 'init',
    alternate: 'config/config.exs'
  }

  var web_dir = dirs->copy()->filter((_, d) => d =~ 'web$')

  if len(web_dir) == 1
    web_dir = web_dir[0]
    const web_alias = util.ToElixirAlias(web_dir)

    projections['lib/' .. web_dir .. '/live/*_live.ex'] = {
      type: 'live',
      alternate: 'test/' .. web_dir .. '/live/{}_live_test.exs',
      template: [
        'defmodule ' .. web_alias .. '.{capitalize}Live do',
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
