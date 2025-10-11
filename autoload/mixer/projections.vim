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

export def Detect()
  if exists('b:projectionist_file') || !exists('g:mixer_enable_projections')
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

  var roots = util.Glob($'{ROOT}/lib/*')->map((_, f) => fnamemodify(f, ':t:r'))->uniq()

  var web_dir =
    roots
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
    'lib/*/router.ex': {
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
    },
    'assets/*.css':  {
      type: 'css'
    },
    'assets/app.css': {
      type: 'css'
    },
    'assets/*.js':  {
      type: 'js'
    },
    'assets/app.js': {
      type: 'js'
    }
  }

  if len(web_dir) == 1
    web_dir = web_dir[0]

    const web_alias = util.ToElixirAlias(web_dir)
    const web_globs = util.Glob(ROOT .. '/lib/**/*')

    var live_defmodule: string
    var web_glob: string

    if match(web_globs, '\/live\/.*_live\.ex') >= 0
      live_defmodule = $'defmodule {web_alias}.{{camelcase|capitalize|dot}}Live do'
      web_glob = $'lib/{web_dir}/live/*_live.ex'
    elseif match(web_globs, '\/live\/') >= 0
      live_defmodule = $'defmodule {web_alias}.{{dirname|camelcase|capitalize}}Live{{dot}}{{basename|camelcase|capitalize|dot}} do'
      web_glob = $'lib/{web_dir}/live/*_live.ex'
    elseif match(web_globs, '_live\.ex$') >= 0
      live_defmodule = $'defmodule {web_alias}.{{camelcase|capitalize|dot}}Live do'
      web_glob = $'lib/{web_dir}/*_live.ex'
    else
      live_defmodule = $'defmodule {web_alias}.{{dirname|camelcase|capitalize}}Live{{dot}}{{basename|camelcase|capitalize|dot}} do'
      web_glob = $'lib/{web_dir}/*_live.ex'
    endif

    const test_glob = web_glob->util.Sub('^lib', 'test')->util.Sub('\.ex$', '_test.exs')

    projections[web_glob] = {
      type: 'live',
      template: [
        live_defmodule,
        $'  use {web_alias}, :live_view',
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
      alternate: util.Sub(web_glob, '*', '{}'),
      dispatch: 'mix test',
      template: [
        util.Sub(live_defmodule, ' do', 'Test do'),
        $'  use {web_alias}.ConnCase, async: true',
        'end'
      ]
    }

    projections[$'lib/{web_dir}/controllers/*_controller.ex'] = {
      type: 'controller',
      alternate: $'test/{web_dir}/controllers/{{}}_controller_test.exs'
    }

    projections[$'lib/{web_dir}/*_plug.ex'] = {
      type: 'plug'
    }

    projections[$'lib/{web_dir}/router.ex'] = {
      type: 'init'
    }
  endif

  for root in roots
    var rtype = util.Sub(root, '^' .. project_name .. '_', '')
    const alias = util.ToElixirAlias(root)

    if rtype == project_name || rtype == 'core'
      rtype = 'domain'
    endif

    projections[$'lib/{root}/*.ex'] = {
      type: rtype,
      alternate: $'test/{root}/{{}}_test.exs',
      related: [
        $'lib/{root}.ex'
      ],
      template: [
        $'defmodule {alias}.{{camelcase|capitalize}} do',
        'end'
      ]
    }

    var use_line: string

    if rtype == 'domain'
      use_line = '  use ' .. alias .. '.DataCase, async: true'
    else
      use_line = '  use ExUnit.Case, async: true'
    endif

    projections[$'test/{root}/*_test.exs'] = {
      type: 'test',
      alternate: $'lib/{root}/{{}}.ex',
      template: [
        $'defmodule {alias}.{{camelcase|capitalize}}Test do',
        use_line,
        'end'
      ]
    }
  endfor

  # Migrations

  for [type, command] in PREFIXES
    exec 'command! -complete=customlist,mixer#projections#MigrationComplete -nargs=?' $'{type}migration' $'EditMigrationFile(<f-mods>, "{command}", <f-args>)'
  endfor

  projections['priv/repo/migrations/*.exs'] = {
    dispatch: mix_project.has_ash ? 'mix ash.migrate' : 'mix ecto.migrate',
  }

  projectionist#append(ROOT, projections)
enddef

def EditMigrationFile(mods: string, command: string, file: string = ""): void
  if file == "0"
    exec mods command 'priv/repo/seeds.exs'

    return
  endif

  const migrations_path = 'priv/repo/migrations'

  if file == ""
    const migrations = util.Glob(migrations_path .. '/*.exs')
    exec mods command migrations[-1]
  else
    exec mods command $'{migrations_path}/{file}.exs'
  endif
enddef

export def MigrationComplete(A: string, L: string, P: number): list<string>
  const migrations =
    util.Glob('priv/repo/migrations/*')
      ->map((_, f) => matchstr(f, 'priv/repo/migrations/\zs\d\+_.*\ze\.exs$'))

  if A != ""
    return matchfuzzy(migrations, A)
  else
    return migrations
  endif
enddef
