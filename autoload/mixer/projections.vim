vim9script

# Projections {{{1

export def Define()
  if !exists('g:loaded_projectionist') || exists('g:mixer_projections_done') || !exists('b:mix_project') || (
      exists('b:mix_project') && filereadable(b:mix_project.root .. "/.projections.json")
      )
    return
  endif

  const name = b:mix_project.name
  final projections = {}

  projections['lib/' .. name .. '.ex'] = {
    'type': 'domain'
  }
  projections['lib/' .. name .. '/*.ex'] = {
    'type': 'domain'
  }

  autocmd User ProjectionistDetect call projectionist#append(root, projections) | echom "hi there"

  g:mixer_projections_done = true

  #   if g:mixer_projections ==# 'replace'
  #     g:projectionist_heuristics['mix.exs'] = projections
  #   elseif g:mixer_projections ==# 'merge' && exists('g:projectionist_heuristics') && has_key(g:projectionist_heuristics, 'mix.exs')
  #     call extend(g:projectionist_heuristics['mix.exs'], projections)
  #   endif
enddef
