vim9script

import autoload "./util.vim"

const PREFIXES = [
  ['E', 'edit'],
  ['S', 'split'],
  ['V', 'vsplit'],
  ['T', 'tabedit'],
  ['O', 'drop'],
  ['D', 'read']
]

def EditMigrationFile(command: string, count: number): void
  if count == 0
    exec command 'priv/repo/seeds.exs'

    return
  endif

  const migrations_path = 'priv/repo/migrations'
  const migrations = util.Glob(migrations_path .. '/*')

  if expand('%:h') ==# migrations_path
    const index = index(migrations, expand('%'))

    exec command migrations[index - 1]
  else
    exec command migrations[-1]
  endif
enddef

export def Detect()
  if exists('b:projectionist_file')
    return
  endif

  const mix_project = get(b:, 'mix_project', {})

  if empty(mix_project)
    return
  endif

  const ROOT = mix_project.root

  if !filereadable(ROOT .. '/mix.exs')
    return
  endif

  const contents = join(readfile(ROOT .. '/mix.exs'), '\n')
  const project_name = matchstr(contents, 'def project\_.*app:\s\+:\zs\k\+\ze')

  var globs = util.Glob(ROOT .. '/lib/*')->map((_, f) => fnamemodify(f, ':t'))
  var dirs = globs->copy()->filter((_, g) => g !~ '\.ex')

  var web_dir =
    dirs
    ->copy()
    ->filter((_, d) => d =~ 'web$')

  var projections: dict<dict<any>>

  # Basic projections

  projections = {
    '*': {console: 'iex -S mix'},
    'mix.exs': {
      type: 'mix',
      alternate: 'mix.lock',
      dispatch: 'mix deps.get'
    },
    'mix.lock': {
      type: 'mixlock',
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
      relative: 'config/config.exs',
      template: [
        'import Config',
      ]
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

  if len(web_dir) == 1
    web_dir = web_dir[0]

    const web_alias = util.ToElixirAlias(web_dir)
    const web_globs = util.Glob(ROOT .. '/lib/**/*')

    var live_defmodule: string
    var web_glob: string

    if match(web_globs, '\/live\/.*_live\.ex') >= 0
      live_defmodule = 'defmodule ' .. web_alias .. '.{camelcase|capitalize|dot}Live do'
      web_glob = 'lib/' .. web_dir .. '/live/*_live.ex'
    elseif match(web_globs, '\/live\/') >= 0
      live_defmodule = 'defmodule ' .. web_alias .. '.{dirname|camelcase|capitalize}Live{dot}{basename|camelcase|capitalize|dot} do'
      web_glob = 'lib/' .. web_dir .. '/live/**_live.ex'
    elseif match(web_globs, '_live\.ex$') >= 0
      live_defmodule = 'defmodule ' .. web_alias .. '.{camelcase|capitalize|dot}Live do'
      web_glob = 'lib/' .. web_dir .. '/*_live.ex'
    else
      live_defmodule = 'defmodule ' .. web_alias .. '.{dirname|camelcase|capitalize}Live{dot}{basename|camelcase|capitalize|dot} do'
      web_glob = 'lib/' .. web_dir .. '/*_live.ex'
    endif

    const test_glob = web_glob->util.Sub('^lib', 'test')->util.Sub('\.ex$', '_test.exs')

    projections[web_glob] = {
      type: 'live',
      alternate: test_glob,
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

    projections[test_glob] = {
      type: 'test',
      alternate: web_glob,
      dispatch: 'mix test'
    }

    projections['lib/' .. web_dir .. '/controllers/*_controller.ex'] = {
      type: 'controller',
      alternate: 'test/' .. web_dir .. '/controllers/{}_controller_test.exs'
    }

    projections['lib/' .. web_dir .. '/*_plug.ex'] = {
      type: 'plug'
    }
  endif

  for dir in dirs
    var type = util.Sub(dir, '^' .. project_name .. '_', '')

    if type == project_name
      type = 'domain'
    endif

    projections['lib/' .. dir .. '/*.ex'] = {
      type: type,
      related: [
        'lib/' .. dir .. '.ex'
      ],
      alternate: 'test/' .. dir .. '/{}_test.exs'
    }
  endfor

  # Migrations

  for [type, command] in PREFIXES
    exec 'command! -count=1' type .. 'migration' 'EditMigrationFile("' .. command .. '", <count>)'
  endfor

  projections['priv/repo/migrations/*.exs'] = {
    dispatch: mix_project.has_ash ? 'mix ash.migrate' : 'mix ecto.migrate',
  }

  projectionist#append(ROOT, projections)
enddef
