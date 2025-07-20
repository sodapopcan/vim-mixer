vim9script

import autoload './util.vim'
import autoload './cursor.vim'
const BUILTINS = [
  'Access', 'Agent', 'Application', 'Atom', 'Base', 'Bitwise', 'Calendar',
  'Code', 'Collectable', 'Config', 'Date', 'Date', 'DateTime', 'Duration',
  'DynamicSupervisor', 'Enum', 'Enumerable', 'Exception', 'File', 'Float',
  'Function', 'GenServer', 'IO', 'Inspect', 'Integer', 'JSON', 'Kernel',
  'Keyword', 'List', 'Macro', 'Map', 'MapSet', 'Module', 'NaiveDateTime',
  'Node', 'OptionParser', 'PartitionSupervisor', 'Path', 'Port', 'Process',
  'Protocol', 'Protocols', 'Range', 'Record', 'Regex', 'Registry', 'Stream',
  'String', 'StringIO', 'Supervisor', 'System', 'Task', 'Time', 'Tuple', 'URI',
  'Version'
]

export def GotoDefinition(): void
  const token = expand('<cword>')

  if token =~# '^\u'
    return
  endif

  var qualified: list<string>

  if !cursor.OnHEEx()
    qualified = expand('<cexpr>')->split('\.')
  endif

  var mod: string

  const fn = qualified[-1]
  if len(qualified) > 1
    mod = qualified[0 : -2]->join('.')
  endif

  var rg_regex: string
  var vim_regex: string

  if cursor.OnHEEx()
    rg_regex = "'\s*def(macro)*?p*? \\<" .. shellescape(fn) .. "\\>\(.*assigns.*\)'"
    vim_regex = '^\s*def\%(macro\)\?p\? \<' .. fn .. '\>(.*assigns.*)'
  else
    rg_regex = "'\s*def(macro)*?p*? \\<" .. shellescape(fn) .. "\\>'"
    vim_regex = '^\s*def\%(macro\)\?p\? \<' .. fn .. '\>'
  endif

  const line = search(vim_regex, 'Wn', 0, 0, () => cursor.OnStringOrComment())

  if line != 0
    exec 'normal! ' .. line .. 'gg^'

    return
  endif

  var results = Grep(rg_regex)

  if len(results) > 0
    HandleResults(results, vim_regex, v:true)
  else
    results = Grep(rg_regex .. " ./deps")

    if len(results) > 0
      HandleResults(results, vim_regex, v:false)
    endif
  endif
enddef

def Grep(cmd: string): list<string>
  return systemlist("rg -l --type elixir " .. cmd)
enddef

def HandleResults(results: list<string>, vim_regex: string, edit: bool): void
  const file = results[0]

  for f in results
    const cmd = edit ? 'edit' : 'view'
    const line = FindDef(readfile(file), vim_regex)

    if line != 0
      exec cmd '+' .. line file
      normal! zz^

      return
    endif
  endfor
enddef

def FindDef(lines: list<string>, regex: string): number
  var line_num = 0
  var in_docstring = v:false

  for line in lines
    line_num += 1

    # Skip comments
    if line =~ '^\s*#'
      continue
    endif

    if line =~ "\\~\k\+\%(\"\"\"\|'''\)"
      in_docstring = v:true
      continue
    endif

    if line =~ "^\s*\%(\"\"\"\|'''\)"
      in_docstring = v:false
      continue
    endif

    if in_docstring
      continue
    endif

    if line =~# regex
      return line_num
    endif
  endfor

  return 0
enddef
