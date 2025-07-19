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

  var results = system("rg -n --type elixir " .. rg_regex)->ParseResults()->filter((_, val) => val !~ '%\(ex\|exs\)$')

  if len(results) > 0
    HandleResults(results, v:true)
  else
    results = system("rg -n --type elixir --no-ignore " .. rg_regex .. " ./deps")->ParseResults()
    echom results

    if len(results) > 0
      HandleResults(results, v:false)
    endif
  endif

  if len(results) > 0
    SearchDefinition(vim_regex)
  endif
enddef

def ParseResults(results: string): list<list<string>>
  return results
    ->split("\n")
    ->map((_, val) => split(val, ':'))
    ->map((_, val) => [val[0], val[1]])
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
    echom search(regex, 'W', 0, 0, () => cursor.OnStringOrComment())
  endif
enddef
