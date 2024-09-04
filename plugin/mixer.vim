if !has('vim9script') ||  v:version < 900
  finish
endif

vim9script

if get(g:, 'loaded_mixer', false)
  finish
endif
g:loaded_mixer = true

import autoload '../autoload/mixer/cmd.vim'

# mixer.vim     Utilities for working with The Elixir Programming Language <3
# Maintainer:   Andrew Haust <https://andrew.hau.st>
# Version:      0.1

augroup mixer
  autocmd!
  autocmd BufNewFile,BufReadPost * call SetupBuf()
augroup END

def SetupBuf()
  if exists(':Mix') != 2
    command -buffer -bang -complete=customlist,cmd.MixComplete -nargs=* Mix call Mix(<bang>0, <f-args>)
  endif

  var [project_root, _, _] = MixerDetect()
enddef

def MixerDetect(): list<any>
  var mix_file = findfile("mix.exs", ".;", 2)
  var nested = 1
  var project_root: string

  if empty(mix_file)
    mix_file = findfile("mix.exs", ".;")
    nested = 0
  endif

  if !empty(mix_file)
    project_root = fnamemodify(mix_file, ':p:h')

    if project_root ==# ""
      project_root = "."
    endif

    return [project_root, mix_file, nested]
  else
    return ['', '', 0]
  endif
enddef
