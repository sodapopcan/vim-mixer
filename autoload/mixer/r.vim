vim9script

import autoload './code.vim'
import autoload './util.vim'
import autoload './cursor.vim'

const CONTROLLER_REGEX = '\s*use\s\+.*:controller\>'
const LIVEVIEW_REGEX = '\s*use\s\+\%(:live_view\>\)'
const HTML_REGEX = '^\s*defmodule\s\+[[:keyword:].]\+HTML do$'

export def DefineCommand()
  command! -nargs=? R R('edit', <q-mods>, <f-args>)
  command! -nargs=? RS R('split', <q-mods>, <f-args>)
  command! -nargs=? RV R('vsplit', <q-mods>, <f-args>)
  command! -nargs=? RT R('tabedit', <q-mods>, <f-args>)
  command! -nargs=? RO R('drop', <q-mods>, <f-args>)
enddef

def R(command: string, mods: string, arg: string = '')
  if IsController()
    const action = GetFunctionName()
    const path = expand('%')
    const html_dir = util.Sub(path, '_controller.ex', '_html')
    const html_file = $'{html_dir}.ex'
    const action_file = $'{html_dir}/{action}.html.heex'

    if util.FileExists(action_file)
      exec mods command action_file
    elseif util.FileExists(html_file)
      exec mods command html_file
      JumpToAction(action)
    else
      util.Error("No file or component exists")
    endif
  elseif IsLiveView()
  elseif IsHTML()
    const action = GetFunctionName()
    const path = expand('%')
    const controller = util.Sub(path, '_html', '_controller')

    if util.FileExists(controller)
      exec mods command controller
      JumpToAction(action)
    else
      util.Error("No file or component exists")
    endif
  elseif IsHEEX()
    const action = expand('%:t:r:r')
    const path = expand('%:h')
    const controller = util.Sub(path, '_html', '_controller') .. '.ex'

    if util.FileExists(controller)
      exec mods command controller
      JumpToAction(action)
    else
      util.Error("No file or component exists")
    endif
  endif
enddef

def IsController(): bool
  return Is(CONTROLLER_REGEX)
enddef

def EditView()
  const path = expand('%')
enddef

def IsLiveView(): bool
  return Is(LIVEVIEW_REGEX)
enddef

def IsHTML(): bool
  return Is(HTML_REGEX)
enddef

def IsHEEX(): bool
  return expand('%:e') == 'heex'
enddef

def Is(regex: string): bool
  return search(regex, 'Wbn') > 0
enddef

def JumpToAction(action: string)
  if GetFunctionName() != action
    search('^\s*def\s\+\<' .. action .. '\>', '', 0, 0, cursor.OnStringOrComment)
  endif
enddef

def GetFunctionName(): string
  const view = winsaveview()

  # This is unfortunate, need to fix this
  code.GetDef('def')
  normal! j

  const name = getline('.')->matchstr('\s*def\s\+\zs\k\+')

  winrestview(view)

  return name
enddef
