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

  var contents = ''
  var project_name = ''
  var project_namespace = ''
  var deps_fun = ''
  var apps_path = ''

  try
    contents = join(readfile(mix_file), '\n')
    project_name = matchstr(contents, 'def project\_.*app:\s\+:\zs\k\+\ze')
    project_namespace = matchstr(contents, 'defmodule \zs\K*/ze.*MixProject$')
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
      'root': project_root,
      'name': project_name,
      'namespace': project_namespace,
      'alias': util.ToElixirAlias(project_name),
      'deps_fun': deps_fun,
      'apps_path': apps_path,
      'nested': nested,
      'bindingPrefix': bindingPrefix,
      'has_phoenix': has_phoenix,
      'has_ecto': has_ecto,
      'has_ash': has_ash,
      'tasks': []
    }

    b:mix_project = g:mix_projects[project_root]

    mix.PopulateMixTasks()
  else
    b:mix_project = g:mix_projects[project_root]
  endif
enddef
