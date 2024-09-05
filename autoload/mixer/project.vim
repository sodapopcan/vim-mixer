vim9script

import autoload './util.vim'
import autoload './mix.vim'
import autoload './cursor.vim'

const HTML_MATCH_WORDS = '<!--:-->,<:>,<\@<=[ou]l\>[^>]*\%(>\|$\):<\@<=li\>:<\@<=/[ou]l>,<\@<=dl\>[^>]*\%(>\|$\):<\@<=d[td]\>:<\@<=/dl>,<\@<=\([^/!][^ \t>]*\)[^>]*\%(>\|$\):<\@<=/\1>'

export def Setup(): void
  if empty(mix_file)
    return
  endif

  # SetCompiler(project_root)

  try
    const contents = join(readfile(mix_file), '\n')
    const project_name = matchstr(contents, 'def project\_.*app:\s\+:\zs\l\k\+\ze')
    const deps_fun = matchstr(contents, 'def project\%(()\)\=\_.*deps:\s\+\zs\w\+\ze\%(()\)\?')
    const apps_path = matchstr(contents, 'def project\_.*apps_path:\s\+"\zs\l\k\+\ze"')
  catch
    const project_name = ''
    const deps_fun = ''
    const apps_path = ''
  endtry

  const has_phoenix = util.FileExists(project_root."/deps/phoenix")
  const has_ecto = util.FileExists(project_root."/deps/ecto_sql")

  var bindingPrefix = 'phx-'

  if empty(apps_path)
    try
      const appjs = join(readfile(project_root.'/assets/js/app.js'), '\n')
      const match = matchstr(appjs, 'bindingPrefix: \(''\|"\)\zs[A-Za-z\-]\+\ze\1')

      if !empty(match)
        bindingPrefix = match
      endif
    catch
    endtry
  endif

  if !has_key(g:mix_projects, project_root)
    g:mix_projects[project_root] = {
      'root': project_root,
      'name': project_name,
      'alias': util.ToElixirAlias(project_name),
      'deps_fun': deps_fun,
      'apps_path': apps_path,
      'nested': nested,
      'bindingPrefix': bindingPrefix,
      'has_phoenix': has_phoenix,
      'has_ecto': has_ecto,
      'tasks': []
    }

    b:mix_project = g:mix_projects[project_root]

    mix.PopulateMixTask()
  else
    b:mix_project = g:mix_projects[project_root]
  endif

  if exists('g:loaded_matchit')
    augroup mixerMatchWords
      autocmd!
      autocmd CursorHold,BufEnter *.ex call DoMatchWords()
    augroup END
  endif

  g:mixer_projections = get(g:, 'mixer_projections', 'replace')

  # if g:mixer_projections !=# "disable"
  #   call DefineProjections()
  # endif
enddef

def SetCommentString(str: string): void
  # This check is done due to a now fixed bug: https://github.com/vim/vim/issues/15462
  if escape(&commentstring, ' ') !=# str
    const cursor_pos = getcurpos()
    exec 'setlocal commentstring=' .. str
    call setpos('.', cursor_pos)
  endif
enddef

def DoMatchWords(): void
  if exists('b:match_words') && !exists('b:elixir_match_words')
    b:elixir_match_words = b:match_words
  endif

  if !exists('b:elixir_match_words')
    return
  endif

  const syn = cursor.OuterSynName()

  if syn =~# 'Heex\|Surface' && syn !~# 'SigilDelimiter'
    b:match_words = HTML_MATCH_WORDS
    call SetCommentString('<%!--\ %s\ --%>')
  else
    b:match_words = b:elixir_match_words
    call SetCommentString('#\ %s')
  endif
enddef

defcompile
