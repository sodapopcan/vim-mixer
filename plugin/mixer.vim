if !has('vim9script') ||  v:version < 900
  finish
endif

vim9script noclear

# mixer.vim     Utilities for working with The Elixir Programming Language <3
# Maintainer:   Andrew Haust <https://andrew.hau.st>
# Version:      0.1.0

if get(g:, 'loaded_mixer', false)
  finish
endif
g:loaded_mixer = true

import autoload 'mixer/mix.vim'
import autoload 'mixer/project.vim'
import autoload 'mixer/textobj.vim'

augroup mixer
  autocmd!
  autocmd BufNewFile,BufReadPost * SetupBuf()
  autocmd FileType elixir,eelixir call textobj.Define()
  autocmd DirChanged * var [project_root, _, _] = g:MixerDetect()
    | if !empty(project_root)
    |   call project.Setup()
    | endif
augroup END

def g:MixerDetect(): list<any>
  var mix_file = findfile('mix.exs', '.;', 2)
  var nested: bool

  if empty(mix_file)
    mix_file = findfile('mix.exs', '.;')
    nested = false
  else
    nested = true
  endif

  var project_root = ''
  if !empty(mix_file)
    project_root = fnamemodify(mix_file, ':p:h')

    if empty(project_root)
      project_root = expand(':p:h')
    endif
  endif

  return [project_root, mix_file, nested]
enddef

def Exists(cmd: string): bool
  return exists(':' .. cmd) == 2
enddef

def SetupBuf(): void
  if !Exists('Mix')
    command -buffer -bang -complete=customlist,mix.MixComplete -nargs=* Mix mix.MixCommand(<bang>false, <f-args>)
  endif

  if !Exists('Iex')
    command -buffer -nargs=0 -bang Iex mix.IexCommand(<bang>false, <q-mods>, <f-args>)
  endif

  var [project_root, mix_file, nested] = g:MixerDetect()

  if (!empty(project_root) && !exists('g:mix_projects')) || (exists('g:mix_projects') && !has_key(g:mix_projects, project_root))
    project.Setup()
  endif

  if exists('g:mix_projects') && has_key(g:mix_projects, project_root)
    b:mix_project = g:mix_projects[project_root]
  endif

  if exists('b:mix_project')
    if !Exists('Deps')
      command -buffer -complete=customlist,mix.DepsComplete -range -bang -nargs=* Deps call mix.DepsCommand(<bang>false, <q-mods>, <range>, <line1>, <line2>, <f-args>)
    endif

    if !Exists('Gen')
      command -buffer -complete=customlist,mix.GenComplete -nargs=* Gen call mix.GenCommand(<f-args>)
    endif
  endif
enddef
