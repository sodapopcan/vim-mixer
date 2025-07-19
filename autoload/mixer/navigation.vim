vim9script

import autoload './util.vim'
import autoload './cursor.vim'

export def GotoDefinition(): void
  const fun = expand('<cword>')
  var regex: string

  if cursor.OnHEEx()
    regex = "'\s*def(macro)*?p*? \\<" .. shellescape(fun) .. "\\>\(.*assigns.*\)'"
  else
    regex = "'\s*def(macro)*?p*? \\<" .. shellescape(fun) .. "\\>'"
  endif

  var results = system("rg -n --type elixir " .. regex)-> ParseResults()

  if len(results) > 0
    HandleResults(results)
  else
    results = system("rg -n --type elixir --no-ignore " .. regex .. " ./deps/**/*")->ParseResults()

    if len(results) > 0
      HandleResults(results)
    endif
  endif
enddef

def ParseResults(results: string): list<list<string>>
  return results
    ->split("\n")
    ->map((_, val) => split(val, ':'))
    ->map((_, val) => [val[0], val[1]])
enddef

def HandleResults(results: list<list<string>>): void
  const [file, line] = results[0]

  if file ==# expand('%')
    exec "normal! " .. line .. "gg"
  else
    exec 'edit +' .. line .. ' ' .. file
    normal! zz
  endif
  normal! ^
enddef
