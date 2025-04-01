vim9script

export def Define()
  var project_name: string

  const project = get(b:, 'mix_project', {})

  if empty(project)
    const [_, mix_file, _] = g:MixerDetect()
    if empty(glob(mix_file))
      return
    endif

    const contents = join(readfile(mix_file), '\n')
    project_name = matchstr(contents, 'def project\_.*app:\s\+:\zs\k\+\ze')
  else
    project_name = project.name
  endif

  g:projectionist_heuristics['mix.exs'] = {
    ['lib/' .. project_name .. '.ex']: {type: 'domain'},
    ['lib/' .. project_name .. '/*.ex']: {
      type: 'domain'
    },
    ['lib/' .. project_name .. '_web.ex']: {type: 'web'},
    ['lib/' .. project_name .. '_web/*.ex']: {
      type: 'web'
    },
    'lib/*.ex': {
      'type': 'lib',
      'alternate': 'test/{}_test.exs',
      'template': ['defmodule {camelcase|capitalize|dot} do', 'end'],
    },
    'test/*_test.exs': {
      'type': 'test',
      'alternate': 'lib/{}.ex',
      'template': ['defmodule {camelcase|capitalize|dot}Test do', '  use ExUnit.Case', '', '  @subject {camelcase|capitalize|dot}', 'end'],
    },
  }
enddef
