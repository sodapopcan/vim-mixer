vim9script

import autoload './code.vim'
import autoload './util.vim'
import autoload './cursor.vim' as cur

const CONTROLLER_REGEX = '\s*use\s\+.*:controller\>'
const LIVEVIEW_REGEX = '\s*use\s\+.*:\%(live_view\|live_component\)\|^defmodule.*Live.*do$\|^\s*use Phoenix.\%(LiveView\|LiveComponent\|Component\)'
const HTML_REGEX = '^\s*defmodule\s\+[[:keyword:].]\+HTML do$\|^\s*use .* :html\>'
const SCHEMA_REGEX = '^\s*use.\{-}Schema'

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
  elseif IsSchema()
    const view = winsaveview()
    :0
    search('^\s*defmodule')
    const schema_module = matchlist(getline('.'), '^\s*defmodule\s\+\([[:keyword:].]\+\)')[1]
    const context_file = util.Camelcase(schema_module->split('\.')[ : -2 ][-1]) .. '.ex'
    winrestview(view)

    const standard_location = expand('%:h:h') .. '/' .. context_file

    if util.FileExists(standard_location)
      Edit(standard_location)
    else
      const colocation = expand('%:h') .. '/' .. context_file

      Edit(colocation)
    endif
  elseif IsMigration()
    const migration = expand('%')
    const migrations = util.Glob('priv/repo/migrations/*.exs')
    const index = index(migrations, migration)
    const prev_migration = migrations[index - 1]

    Edit(prev_migration)
  elseif IsEndpointOrRouter()
    var path = expand('%')

    if path =~ 'endpoint\.ex$'
      Edit(expand('%:h') .. '/router.ex')
    else
      Edit(expand('%:h') .. '/endpoint.ex')
    endif
  else
    # We're just gonna wing it and try and find a related file based on the
    # function name and modules in it.  We're going to assume it's a Phoenix Context.
    const function_name = cur.FunctionName()->split('_')->map((_, n) => util.Singularize(n))->join(' ')
    final basenames: list<string> = []
    final candidates: list<list<any>> = []

    for file in util.Glob(expand('%:r') .. '/**/*.ex')
      const name = fnamemodify(file, ':t:r')->split('_')->map((_, n) => util.Singularize(n))->join(' ')
      basenames->add(name)
    endfor

    for basename in basenames
      const results = matchfuzzypos([function_name], basename)
      const score = results[2]

      if len(score) > 0
        candidates->add([basename, score[0]])
      endif
    endfor

    if len(candidates) > 0
      const result = candidates[0][0]

      Edit(expand('%:r') .. '/' .. result .. '.ex')
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

def IsSchema(): bool
  return Is(SCHEMA_REGEX)
enddef

def IsMigration(): bool
  return expand('%') =~ 'repo/migrations'
enddef

def IsEndpointOrRouter(): bool
  return expand('%') =~ 'endpoint\.ex$\|router\.ex'
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
