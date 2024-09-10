vim9script

import autoload './cursor.vim'
import autoload './util.vim'

# Jump to event handler/hook {{{1

export def DefineFindEvent(): void
  if !empty(system('command -v git'))
    nnoremap <silent> <buffer> <c-]> :call <sid>FindEvent()<cr>
  endif
enddef

def FindEvent(): void
  const cursor_word = expand('<cWORD>')
  const prefix = b:mix_project.bindingPrefix

  if cursor_word !~ prefix
    exec "normal! \<c-]>"

    return
  endif

  var char: string

  if util.Matches(cursor_word, prefix .. '.\+=''')
    char = ''''
  elseif util.Matches(cursor_word, prefix .. '.\+="')
    char = '"'
  else
    exec "normal! \<c-]>"

    return
  endif

  var cursor_pos = cursor.Pos()

  # Probably a better way to do this.
  var save_i = @i
  exec 'normal! "iyi' .. char
  const token = @i
  @i = save_i

  if cursor_word =~ '^' .. prefix .. 'hook'
    call HandlePhxHook(token, cursor_pos)
  else
    call HandlePhxEvent(token, cursor_pos)
  endif
enddef

def HandlePhxHook(token: string, cursor_pos: list<number>): void
  var results = systemlist("git grep -n '" .. token .. " = ' -- :/'*.js' :/'*.ts'")

  if len(results) > 0
    const result = split(results[0], ':')
    var file = result[0]
    var lnr = result[1]
    normal! m'
    exec "silent keepjumps edit" file
    exec "keepjumps :" .. lnr
  else
    if exists('b:mix_project')
      var files = FindJsFile(token)

      if !empty(files)
        normal! m'

        exec "silent keepjumps edit" files[0]
      else
        call cursor.Set(cursor_pos)
        echom "Can't find definition"

        return
      endif
    else
      call cursor.Set(cursor_pos)

      echom "Not a mix project"
    endif
  endif
enddef

def FindJsFile(token_arg: string): list<string>
  final tracked = systemlist("git ls-files -- '*.js' ':!:priv/'")
  final untracked = systemlist("git ls-files --others -- '*.js' ':!:deps/' ':!:priv/'")
  const files = extend(tracked, untracked)
  var token = util.Gsub(token_arg, '-\|_', '')

  return matchfuzzy(files, token)
enddef

def HandlePhxEvent(token: string, cursor_pos: list<number>): void
  var template = ''
  var flags = 's'

  if expand('%:e') =~ 'heex\|sface'
    template = expand('%')
    flags = ''
    const exfile = util.Sub(template, '\.html\.\<heex\|sface\>$', '\.ex')

    if util.FileExists(exfile)
      normal! m'

      exec "silent keepjumps edit" exfile
    else
      echom "Cannot find Elixir file"

      return
    endif
  endif

  if !search('def handle_event(\%(\%(\s\|\n\)\+\)\?"\<' .. token .. '\>', flags)
    echom "Cannot find definition"

    if !empty(template)
      exec "silent keepjumps edit" template
    endif

    call cursor.Set(cursor_pos)
  endif
enddef
