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
import autoload 'mixer/projections.vim'
import autoload 'mixer/r.vim'
import autoload 'mixer/grep.vim'

def g:MixerDetect(): list<any>
  var mix_file = findfile('mix.exs', '.;', 2)
  var lib_dir = finddir('lib', ',;', 2)

  var nested = true

  if empty(mix_file)
    mix_file = findfile('mix.exs', '.;')
    lib_dir = finddir('lib/', '.;')
    nested = false
  endif

  mix_file = util.Sub(mix_file, '^\w\+://', '')
  lib_dir = util.Sub(lib_dir, '^\w\+://', '')

  if empty(mix_file) || empty(lib_dir)
    return ['', '', '']
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

var mix_project_root: string

augroup mixer
  autocmd!
  autocmd FileType elixir,eelixir textobj.Define()
  autocmd FileType elixir,eelixir integrations.Define()
  autocmd CursorHold,BufEnter,VimEnter *.ex,*.exs elixir.SetMatchWords()
  autocmd CursorHold,BufEnter,VimEnter *.ex,*.exs elixir.SetCommentString()
  autocmd CursorHold,BufEnter,VimEnter *.ex,*.exs elixir.SetIsKeyword()
  autocmd FileType eelixir b:match_words = elixir.HTML_MATCH_WORDS
    | exec "set commentstring=" .. elixir.HEEX_COMMENTSTRING
    | exec "set iskeyword+=-"
  autocmd DirChanged * [mix_project_root, _, _] = g:MixerDetect()
    | if !empty(mix_project_root)
    |   project.Setup()
    | endif
  autocmd User ProjectionistDetect | SetupBuf() | projections.Detect()
  autocmd BufReadPost * if !exists('*ProjectionistHas') | SetupBuf() | endif
  autocmd BufReadPost * if exists('b:mix_project') | r.DefineCommand() | endif
augroup END

def SetupBuf()
  command! -buffer -bang -complete=customlist,mix.MixComplete -nargs=* Mix mix.MixCommand(<bang>false, <f-args>)
  command! -buffer -range -nargs=* -complete=file IEx mix.IExCommand(<q-mods>, <range>, <line1>, <line2>, <f-args>)
  command! -buffer -bang -complete=customlist,mix.GenComplete -nargs=* Gen call mix.GenCommand(<bang>false, <f-args>)

  var [project_root, mix_file, nested] = g:MixerDetect()

  SetCompiler(project_root)

  if (!empty(project_root) && !exists('g:mix_projects')) || (exists('g:mix_projects') && !has_key(g:mix_projects, project_root))
    project.Setup()
  endif

  if exists('g:mix_projects') && has_key(g:mix_projects, project_root)
    b:mix_project = g:mix_projects[project_root]
  endif

  if exists('b:mix_project')
    command! -buffer -complete=customlist,mix.DepsComplete -range -bang -nargs=* Deps call mix.DepsCommand(<bang>false, <q-mods>, <range>, <line1>, <line2>, <f-args>)

    nnoremap <silent> <buffer> <Plug>(mixer-jump-to-definition) :call <sid>grep.GotoDefinition('edit')<cr>
    nnoremap <silent> <buffer> <Plug>(mixer-jump-to-definition-follow) :call <sid>grep.GotoDefinition('edit', v:true)<cr>
    nnoremap <silent> <buffer> <Plug>(mixer-jump-to-definition-split) :call <sid>grep.GotoDefinition('split')<cr>
    nnoremap <silent> <buffer> <Plug>(mixer-jump-to-definition-split-follow) :call <sid>grep.GotoDefinition('split', v:true)<cr>
    nnoremap <silent> <buffer> <Plug>(mixer-jump-to-definition-tab) :call <sid>grep.GotoDefinition('tabedit')<cr>
    nnoremap <silent> <buffer> <Plug>(mixer-jump-to-definition-tab-follow) :call <sid>grep.GotoDefinition('tabedit', v:true)<cr>
    nnoremap <silent> <buffer> <Plug>(mixer-hover) :call <sid>grep.Hover()<cr>
    nnoremap <silent> <buffer> <Plug>(mixer-find-usages) :call <sid>grep.FindUsages()<cr>

    util.SetLocalMap('gd', 'mixer-jump-to-definition')
    util.SetLocalMap('gD', 'mixer-jump-to-definition-follow')
    util.SetLocalMap('<c-w>d', 'mixer-jump-to-definition-split')
    util.SetLocalMap('<c-w>D', 'mixer-jump-to-definition-split-follow')
    util.SetLocalMap('<c-w>gd', 'mixer-jump-to-definition-tab')
    util.SetLocalMap('<c-w>gD', 'mixer-jump-to-definition-tab-follow')
    util.SetLocalMap('[d', 'mixer-hover')
    util.SetLocalMap('gR', 'mixer-find-usages')

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
