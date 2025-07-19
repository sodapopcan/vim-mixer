vim9script

import autoload './util.vim'
import autoload './mix.vim'
import autoload './cursor.vim'

export def Setup()
  var [project_root, mix_file, nested] = g:MixerDetect()

  if empty(mix_file)
    return
  endif

  g:mix_projects = get(g:, 'mix_projects', {})

  var contents: string
  var project_name: string
  var project_namespace: string
  var deps_fun: string
  var apps_path: string

  try
    contents = join(readfile(mix_file), '\n')
    project_name = matchstr(contents, 'def project\_.*app:\s\+:\zs\k\+\ze')
    project_namespace = matchstr(contents, 'defmodule \zs\k\+\ze\.MixProject')
    deps_fun = matchstr(contents, 'def project\%(()\)\=\_.*deps:\s\+\zs\w\+\ze\%(()\)\?')
    apps_path = matchstr(contents, 'def project\_.*apps_path:\s\+"\zsk\+\ze"')
  catch
  endtry

  const has_phoenix = util.FileExists(project_root .. "/deps/phoenix")
  const has_ecto = util.FileExists(project_root .. "/deps/ecto_sql")
  const has_ash = util.FileExists(project_root .. "/deps/ash")

  var bindingPrefix = 'phx-'

  if empty(apps_path)
    try
      const appjs = join(readfile(project_root .. '/assets/js/app.js'), '\n')
      const match = matchstr(appjs, 'bindingPrefix: \(''\|"\)\zs[A-Za-z\-]\+\ze\1')

      if !empty(match)
        bindingPrefix = match
      endif
    catch
    endtry
  endif

  if has_ash && get(g:, 'mixer_syntax_highlighting', 1)
    syn match elixirPhoenixRouter "\%(\C\(^\s*\)\@<=\<\(create\|read\|update\|destroy\|defaults\|define\|calculations\|calculate\|aggregates\|identities\|admin\|authentication\|tokens\|resource\|code_interface\|pub_sub\|preparations\|changes\|validations\|multitenancy\|attributes\=\|actions\=\|policy\|policies\|relationships\|postgres\|sqlite\)\>\)\%( =\)\@!"
    hi link elixirPhoenixRouter Keyword
  endif

  if !has_key(g:mix_projects, project_root)
    g:mix_projects[project_root] = {
      root: project_root,
      name: project_name,
      alias: util.ToElixirAlias(project_name),
      namespace: project_namespace,
      deps_fun: deps_fun,
      apps_path: apps_path,
      nested: nested,
      bindingPrefix: bindingPrefix,
      has_phoenix: has_phoenix,
      has_ecto: has_ecto,
      has_ash: has_ash,
      tasks: []
    }

    b:mix_project = g:mix_projects[project_root]

    mix.PopulateMixTasks()
  else
    b:mix_project = g:mix_projects[project_root]
  endif
enddef

# TODO: To make this better we should check that either there is both
# a lib/foo directory and either a lib/foo.ex or lib/foo/foo.ex file.
export def GetRootModules(): list<string>
  return glob('lib/*', 0, 1)
    -> filter((_, f) => f !~# '\.' || f =~# '\.ex$')
    -> map((_, f) => fnamemodify(f, ':t:r'))
    -> filter((_, f) => f != 'mix')
    -> uniq()
    -> map((_, f) => util.ToElixirAlias(f))
enddef

export def IsProjectModule(module: string): bool
  const ns = module->split('\.')[0]

  return util.InList(GetRootModules(), ns)
enddef

export def GetElixirPath(): string
  system("command -v asdf")

  if v:shell_error == 0
    var elixir_path = system('asdf where elixir')->trim()
    elixir_path = elixir_path .. '/lib/elixir/lib/'

    return elixir_path
  endif

  return ''
enddef
