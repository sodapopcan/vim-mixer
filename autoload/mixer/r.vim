vim9script

import autoload './code.vim'
import autoload './util.vim'
import autoload './cursor.vim' as cur

const CONTROLLER_REGEX = '\s*use\s\+.*:controller\>'
const LIVEVIEW_REGEX = '\s*use\s\+.*:\%(live_view\|live_component\)\|^defmodule.*Live.*do$\|^\s*use Phoenix.\%(LiveView\|LiveComponent\|Component\)'
const HTML_REGEX = '^\s*defmodule\s\+[[:keyword:].]\+HTML do$\|^\s*use .* :html\>'

export def DefineCommand()
  command! -buffer -count -nargs=? R R('edit', <range>, <count>, <q-mods>, <f-args>)
  command! -buffer -count -nargs=? RS R('split', <range>, <count>, <q-mods>, <f-args>)
  command! -buffer -count -nargs=? RV R('vsplit', <range>, <count>, <q-mods>, <f-args>)
  command! -buffer -count -nargs=? RT R('tabedit', <range>, <count>, <q-mods>, <f-args>)
  command! -buffer -count -nargs=? RO R('drop', <range>, <count>, <q-mods>, <f-args>)
enddef

def R(command: string, range: number, count: number, mods: string, arg: string = '')
  const original_line = line('.')
  var context_line = original_line

  if range == 1
    context_line = count
  endif

  const original_view = winsaveview()

  const Edit = (file: string) => {
    exec $':{original_line}'
    exec mods command file
  }

  const Reset = () => winrestview(original_view)

  exec $':{context_line}'

  if IsController()
    const action = cur.FunctionName()
    const path = expand('%')
    const html_dir = util.Sub(path, '_controller.ex', '_html')
    const html_file = $'{html_dir}.ex'
    const action_file = $'{html_dir}/{action}.html.heex'

    if util.FileExists(action_file)
      Edit(action_file)
    elseif util.FileExists(html_file)
      Edit(html_file)
      JumpToAction(action)
    else
      Reset()
      util.Error("No file or component exists")
    endif
  elseif IsLive()
    const heex_file = $'{expand('%:r')}.html.heex'

    if util.FileExists(heex_file)
      Edit(heex_file)
    else
      var lnum = 0
      var col = 0

      const jumps = getjumplist()[0]
        ->reverse()
        ->filter((_, i) => i.bufnr == bufnr())

      const view = winsaveview()
      normal! ^
      const started_in_heex = cur.SynstackStr() =~ 'Heex'

      for jump in jumps
        cursor(jump.lnum, jump.col + 1)

        const in_heex = cur.SynstackStr() =~ 'Heex'

        if (started_in_heex && in_heex) || (!started_in_heex && !in_heex)
          continue
        else
          lnum = jump.lnum
          col = jump.col + 1

          break
        endif
      endfor

      winrestview(view)

      if lnum != 0
        EditEmbedded(command, lnum, col)
      else
        if started_in_heex
          lnum = search('^\s*def mount\|^defmodule', 'n', 0, 0, cur.OnStringOrComment)
        else
          lnum = search('^\s*\~H', 'n', 0, 0, cur.OnStringOrComment)
        endif

        EditEmbedded(command, lnum, 1)
      endif
    endif
  elseif IsHTML()
    const action = cur.FunctionName()
    const path = expand('%')
    const controller = util.Sub(path, '_html', '_controller')

    if util.FileExists(controller)
      Edit(controller)
      JumpToAction(action)
    else
      Reset()
      util.Error("No file or component exists")
    endif
  elseif IsHEEX()
    const action = expand('%:t:r:r')
    const controller = util.Sub(expand('%:h'), '_html', '_controller') .. '.ex'
    const live = $'{expand('%:r:r')}.ex'

    if util.FileExists(controller)
      Edit(controller)
      JumpToAction(action)
    elseif util.FileExists(live)
      Edit(live)
    else
      Reset()
      util.Error("No file or component exists")
    endif
  endif
enddef

def IsController(): bool
  return Is(CONTROLLER_REGEX)
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
  const result = search(regex, 'bnc') > 0

  return result
enddef

def JumpToAction(action: string)
  if cur.FunctionName() != action
    search('^\s*def\s\+\<' .. action .. '\>', '', 0, 0, cur.OnStringOrComment)
  endif
enddef

def EditEmbedded(command: string, lnum: number, col: number)
  if lnum != 0
    if command == 'edit'
      normal! m'
      cursor(lnum, col)
    else
      exec command $'+{lnum}' expand('%')
    endif
  else
    util.Error("Couldn't find anything")
  endif
enddef
