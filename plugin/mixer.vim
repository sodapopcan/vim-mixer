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

import autoload 'mixer/util.vim'
import autoload 'mixer/elixir.vim'
import autoload 'mixer/mix.vim'
import autoload 'mixer/project.vim'
import autoload 'mixer/phx.vim'
import autoload 'mixer/textobj.vim'
import autoload 'mixer/integrations.vim'

var mix_project_root: string

augroup mixer
  autocmd!
  autocmd BufNewFile,BufReadPost * SetupBuf()
  autocmd FileType elixir,eelixir call textobj.Define()
  autocmd FileType elixir,eelixir call integrations.Define()
  autocmd CursorHold,BufEnter,VimEnter *.ex,*.exs call elixir.SetMatchWords()
  autocmd CursorHold,BufEnter,VimEnter *.ex,*.exs call elixir.SetCommentString()
  autocmd FileType eelixir b:match_words = elixir.HTML_MATCH_WORDS
    | exec "set commentstring=" .. elixir.HEEX_COMMENTSTRING
  autocmd DirChanged * [mix_project_root, _, _] = g:MixerDetect()
    | if !empty(mix_project_root)
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

def SetupBuf()
  if !Exists('Mix')
    command -buffer -bang -complete=customlist,mix.MixComplete -nargs=* Mix mix.MixCommand(<bang>false, <f-args>)
  endif

  if !Exists('IEx')
    command -buffer -nargs=0 -bang IEx mix.IExCommand(<bang>false, <q-mods>, <f-args>)
  endif

  if !Exists('Gen')
    command -buffer -bang -complete=customlist,mix.GenComplete -nargs=* Gen call mix.GenCommand(<bang>false, <f-args>)
  endif

  var [project_root, mix_file, nested] = g:MixerDetect()

  SetCompiler(project_root)

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

    if b:mix_project.has_phoenix
      phx.DefineFindEvent()
    endif
  endif
enddef

def SetCompiler(root: string)
  var [project_root, mix_file, nested] = g:MixerDetect()

  if util.FileExists(root .. '/Makefile') && &makeprg ==# 'make'
    return
  elseif &ft =~ 'elixir' && expand('%:p') =~ '_test.exs$' && util.RuntimeExists('compiler/exunit.vim')
    compiler exunit
  elseif &ft =~ 'elixir' && util.RuntimeExists('compiler/mix.vim')
    compiler mix
  endif
enddef
