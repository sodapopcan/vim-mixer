vim9script

import autoload './code.vim'
import autoload './util.vim'
import autoload './cursor.vim'

const CONTROLLER_REGEX = '\s*use\s\+.*:controller\>'
const LIVEVIEW_REGEX = '\s*use\s\+.*:\%(live_view\|live_component\)\|^defmodule.*Live.*do$\|^\s*use Phoenix.\%(LiveView\|LiveComponent\|Component\)'
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
    Inspect "[action]"
    echom action
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
  elseif IsLive()
    const heex_file = $'{expand('%:r')}.html.heex'

    if util.FileExists(heex_file)
      exec mods command heex_file
    else
      var lnum = 0
      const jumps = getjumplist()[0]->reverse()->filter((_, i) => i.bufnr == bufnr())

      const view = winsaveview()
      normal! ^
      const started_in_heex = cursor.SynstackStr() =~ 'Heex'

      for jump in jumps
        exec ':' .. jump.lnum

        const in_heex = cursor.SynstackStr() =~ 'Heex'

        if (started_in_heex && in_heex) || (!started_in_heex && !in_heex)
          continue
        else
          lnum = jump.lnum
          break
        endif
      endfor

      winrestview(view)

      if lnum != 0
        EditEmbedded(command, lnum)
      else
        if started_in_heex
          lnum = search('^\s*def mount\|^defmodule', 'n', 0, 0, cursor.OnStringOrComment)
        else
          lnum = search('^\s*\~H', 'n', 0, 0, cursor.OnStringOrComment)
        endif

        EditEmbedded(command, lnum)
      endif
    endif
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
    const controller = util.Sub(expand('%:h'), '_html', '_controller') .. '.ex'
    const live = $'{expand('%:r:r')}.ex'

    if util.FileExists(controller)
      exec mods command controller
      JumpToAction(action)
    elseif util.FileExists(live)
      exec mods command live
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

def IsLive(): bool
  return Is(LIVEVIEW_REGEX)
enddef

def IsHTML(): bool
  return Is(HTML_REGEX)
enddef

def IsHEEX(): bool
  return expand('%:e') == 'heex'
enddef

def Is(regex: string): bool
  const view = winsaveview()
  normal! $
  const result = search(regex, 'Wbn') > 0
  winrestview(view)

  return result
enddef

def JumpToAction(action: string)
  if GetFunctionName() != action
    search('^\s*def\s\+\<' .. action .. '\>', '', 0, 0, cursor.OnStringOrComment)
  endif
enddef

def EditEmbedded(command: string, lnum: number)
  if lnum != 0
    normal! m'
    if command == 'edit'
      exec ':' .. lnum
    else
      exec command '+' .. lnum expand('%')
    endif
  else
    util.Error("Couldn't find anything")
  endif
enddef

def GetFunctionName(): string
  const view = winsaveview()

  var name = ''

  if getline('.') =~ '^\s*\<def\>'
    name = getline('.')->matchstr('\s*def\s\+\zs\k\+')
  else
    var cur_pos = [line('.'), 0]
    var def_lnum = search('\<def\>', 'Wbc', 0, 0, cursor.OnStringOrComment)
    searchpos('\<do\>', 'W', 0, 0, cursor.OnStringOrComment)
    var end_pos = searchpairpos('\<do\>\|\<fn\>', '', '\<end\>', 'W', cursor.OnStringOrComment)

    if util.InRange(cur_pos, [def_lnum, 1], end_pos)
      name = getline(def_lnum)->matchstr('\s*def\s\+\zs\k\+')
    else
      def_lnum = search('\<def\>', 'Wc', 0, 0, cursor.OnStringOrComment)
      searchpos('\<do\>', 'W', 0, 0, cursor.OnStringOrComment)
      end_pos = searchpairpos('\<do\>\|\<fn\>', '', '\<end\>', 'W', cursor.OnStringOrComment)

      if util.InRange(cur_pos, [def_lnum, 1], end_pos)
        name = getline(def_lnum)->matchstr('\s*def\s\+\zs\k\+')
      endif
    endif

  endif

  winrestview(view)

  return name
enddef
