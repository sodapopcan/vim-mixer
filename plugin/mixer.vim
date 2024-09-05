if !has('vim9script') ||  v:version < 900
  finish
endif

vim9script

if get(g:, 'loaded_mixer', false)
  finish
endif
g:loaded_mixer = true

import autoload '../autoload/mixer/mix.vim'
import autoload '../autoload/mixer/project.vim'

# mixer.vim     Utilities for working with The Elixir Programming Language <3
# Maintainer:   Andrew Haust <https://andrew.hau.st>
# Version:      0.1.0

augroup mixer
  autocmd!
  autocmd BufNewFile,BufReadPost * SetupBuf()
augroup END

def g:MixerDetect(): list<any>
  var mix_file = findfile('mix.exs', '.;', 2)
  var nested = true
  var project_root = ''

  if empty(mix_file)
    mix_file = findfile('mix.exs', '.;')
    nested = false
  endif

  if !exists('g:mix_projects')
    final g:mix_projects = {}
  endif

  if !empty(mix_file)
    project_root = fnamemodify(mix_file, ':p:h')

    if empty(project_root)
      project_root = expand(':p:h')
    endif
  endif

  return [project_root, mix_file, nested]
enddef

def SetupBuf(): void
  if exists(':Mix') != 2
    command -buffer -bang -complete=customlist,mix.MixComplete -nargs=* Mix mix.MixCommand(<bang>0, <f-args>)
  endif

  # var [project_root, _, _] = g:MixerDetect()

  # if !empty(project_root) && !exists('g:mix_projects') || (exists('g:mix_projects') && !has_key(g:mix_projects, project_root))
  #   project.Setup()
  # endif
enddef

defcompile
