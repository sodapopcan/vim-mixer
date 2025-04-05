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

  var domain: string
  const domain_index = index(files, project_name)

  if domain_index > -1
    domain = remove(files, domain_index)
  endif

  projections['mix.exs'] = {
    type: 'mix',
    alternate: 'mix.lock',
    dispatch: 'mix deps.get'
  }

  projections['lib/mix/*.ex'] = {
    type: 'mix'
  }

  projections['test/*_test.exs'] = {
    type: 'test',
    alternate: 'lib/{}.ex'
  }

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

    const path = util.Sub(dir, '\.ex$', '')

    projections['lib/' .. dir .. '/*.ex'] = {
      type: type,
      alternate: 'test/' .. dir .. '/{}_test.exs'
    }
  endfor
  projectionist#append('/Users/andrwe/GroupCollect/ops', projections)
enddef
