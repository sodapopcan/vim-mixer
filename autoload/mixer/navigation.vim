vim9script

import autoload './util.vim'
import autoload './cursor.vim'

export def GotoDefinition(): void
  const fn = expand('<cword>')
  var rg_regex: string
  var vim_regex: string

  if cursor.OnHEEx()
    rg_regex = "'\s*def(macro)*?p*? \\<" .. shellescape(fn) .. "\\>\(.*assigns.*\)'"
    vim_regex = '^\s*def\%(macro\)\?p\? \<' .. fn .. '\>(.*assigns.*)'
  else
    rg_regex = "'\s*def(macro)*?p*? \\<" .. shellescape(fn) .. "\\>'"
    vim_regex = '^\s*def\%(macro\)\?p\? \<' .. fn .. '\>'
  endif

  var results = Grep(rg_regex)

  if len(results) > 0
    HandleResults(results, v:true)
  else
    results = Grep(rg_regex .. " ./deps")

    if len(results) > 0
      HandleResults(results, v:false)
    endif
  endif

  if len(results) > 0
    SearchDefinition(vim_regex)
  endif
enddef

def Grep(cmd: string): list<list<string>>
  return system("rg -n --type elixir " .. cmd)
    ->split("\n")
    ->map((_, val) => split(val, ':'))
    ->map((_, val) => [val[0], val[1]])
    ->filter((_, val) => val[0] !~ '%\(ex\|exs\)$')
enddef

def HandleResults(results: list<list<string>>, edit: bool): void
  const [file, line] = results[0]

  if file ==# expand('%')
    exec "normal! " .. line .. "gg"
  else
    const cmd = edit ? 'edit' : 'view'
    exec 'view +' .. line .. ' ' .. file
    normal! zz
  endif
enddef

def SearchDefinition(regex: string): void
  if cursor.OnStringOrComment()
    search(regex, 'W', 0, 0, () => cursor.OnStringOrComment())
  endif
enddef
