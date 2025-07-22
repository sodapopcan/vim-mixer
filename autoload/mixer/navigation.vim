vim9script

import autoload './util.vim'
import autoload './cursor.vim' as cur

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
  const fn = expand('<cword>')

  if fn =~# '^\u'
    return
  endif

  # While <cexpr> works beautifully in Elixir files, it does not work in HEEx
  # files, so here we are.
  final aliases: list<string> = []
  var view = winsaveview()
  # Move back to the start of the word.
  normal! wb

  if cur.Char(col('.') - 2) != '<'
    const curr_line_num = line('.')

    while cur.Char(col('.') - 1) == '.' && line('.') == curr_line_num
      normal! bb
      aliases->add(expand('<cword>'))
    endwhile
  endif
  winrestview(view)

  # First let's check if this function is local.
  var rg_regex: string
  var vim_regex: string

  if cur.OnHEEx()
    rg_regex = "'\s*def(macro|delegate)*?p*? \\<" .. shellescape(fn) .. "\\>\(.*assigns.*\)'"
    vim_regex = '^\s*def\%(macro\|delegate\)\=p\= \<' .. fn .. '\>(.*assigns.*)'
  else
    rg_regex = "'\s*def(macro|delegate)*?p*? \\<" .. shellescape(fn) .. "\\>'"
    vim_regex = '^\s*def\%(macro\|delegate\)\=p\= \<' .. fn .. '\>'
  endif

  view = winsaveview()
  normal! gg
  const line = search(vim_regex, 'Wn', 0, 0, () => cur.OnStringOrComment())
  winrestview(view)

  if line != 0
    exec 'normal!' line .. 'gg^'

    return
  endif

  # All right, so now we gotta grep.
  # Let's start by getting the `use` directives.

  final deps = {}

  view = winsaveview()
  try
    search('defmodule', 'bW', 0, 0, () => cur.OnStringOrComment())
    while search('^\s*use', 'W', 0, 0, () => cur.OnStringOrComment()) != 0
      const l = getline('.')
      const mod = matchstr(l, '^\s*use\s\+\zs\%(\k\|\.\)\+')
      # TODO: Check if it's actually a project module.
      if mod =~# b:mix_project.namespace
        const res = Grep("'defmodule " .. mod .. " do' ./lib ./test")

        deps->extend(ResolveDeps(readfile(res[0])))
      else
        # If the `use` is coming from a dependency, we're not going to read it
        # and just treat it as an import.
        deps[mod] = {directive: 'import', module: mod}
      endif
    endwhile
  catch
  finally
    winrestview(view)
  endtry

  deps->extend(ResolveDeps(readfile(expand('%'))))

  const alias = aliases->join('.')
  var module: string
  if has_key(deps, alias)
    module = deps[alias].module
  endif

  var results = Grep(rg_regex)

  if len(results) > 0
    if len(results) > 1
      var res =
        results
        ->copy()
        ->filter((_, f) => !matchstrlist(readfile(f), 'defmodule ' .. module .. ' do')->empty())

      const file = res[0]
      const l = FindDef(readfile(file), vim_regex)
      exec 'edit +' .. l file
      normal! zz^
    else
      HandleResults(results, vim_regex, v:true)
    endif
  else
    results = Grep(rg_regex .. " ./deps")

    if len(results) > 0
      HandleResults(results, vim_regex, v:false)
    endif
  endif
enddef

def Grep(cmd: string): list<string>
  const results = systemlist("rg -l --type elixir " .. cmd)

  if v:shell_error > 0
    return []
  else
    return results
  endif
enddef

def HandleResults(results: list<string>, vim_regex: string, edit: bool): void
  for file in results
    const cmd = edit ? 'edit' : 'view'
    const line = FindDef(readfile(file), vim_regex)

    if line != 0
      exec cmd '+' .. line file
      normal! zz^

      break
    endif
  endfor
enddef

class DocString
  var in: bool
  var DOCSTRING_REGEX = '"""\|'''''''

  def new()
    this.in = v:false
  enddef

  def Update(line: string)
    if line =~ this.DOCSTRING_REGEX && this.in == v:false
      this.in = v:true
    elseif line =~ this.DOCSTRING_REGEX && this.in == v:true
      this.in = v:false
    endif
  enddef
endclass

def FindDef(lines: list<string>, regex: string): number
  var line_num = 0
  var docstring = DocString.new()

  for line in lines
    line_num += 1

    docstring.Update(line)

    if docstring.in || line =~ '^\s*#'
      continue
    endif

    if line =~# regex
      return line_num
    endif
  endfor

  return 0
enddef

# const QUALIFIED_REGEX = 's*\zs\(require\|alias\)\s*\([[:alnum:]\|\.]\+\){\=\%(,\s*as:\s\(\k\+\)\)\='
# const IMPORT_REGEX = 's*\zs\(import\)\s*\([[:alnum:]\.]\+\){\=\%(,\s*\(only\|except\):\s*\(\[\_.\{-}\]\)\)\='
const DIRECTIVE_REGEX = '^\s*\zs\(\<import\>\|\<require\>\|\<alias\>\|\<use\>\)\s\+\([[:alnum:]\|\.]\+\)'
const MAPPING = {'{': '}', '[': ']'}

def ResolveDeps(lines: list<string>): dict<any>
  var docstring = DocString.new()
  var multiend = '' # '}' or ']'

  final deps = {}
  final accumulator: list<string> = []

  for line in lines
    docstring.Update(line)

    if docstring.in || line =~# '^\s*#'
      continue
    endif

    const type = matchstr(line, '^\s*\%(\<import\>\|\<require\>\|\<alias\>\)')

    if !empty(type)
      const open = matchstr(line, '{\|\[')

      if type != 'use' && !empty(open) && line !~# MAPPING[open]
        multiend = MAPPING[open]
      endif

      accumulator->add(trim(line))
    elseif !empty(multiend)
      if line =~# multiend .. '$'
        multiend = ''
      endif

      accumulator[-1] = accumulator[-1] .. trim(line)
    endif
  endfor

  for line in accumulator
    const [full, directive, module, _, _, _, _, _, _, _] = matchlist(line, DIRECTIVE_REGEX)

    const expandables = matchstr(line, '{\zs.*\ze}')

    if !empty(expandables)
      for alias in expandables->split(',')->map((_, v) => trim(v))
        deps[alias] = {directive: directive, module: module .. alias} 
      endfor
    elseif directive == 'alias'
      if line =~# 'as:\s\+\k\+'
        const alias = matchstr(line, 'as:\s\+\zs\k\+')

        deps[alias] = {directive: directive, module: module}
      else
        const alias = module->split('\.')[-1]

        deps[alias] = {directive: directive, module: module}
      endif
    elseif directive == 'import' && line =~# 'only:\|except:'
      deps[module] = {
        directive: directive,
        module: module
      }

      const matches = matchlist(line, '\(only:\|except:\) \[\zs.*\ze\]')

      if len(matches) > 0
        const fns = matches[0]->split(',')->map((_, v) => v->split(': '))
        const option = matches[1]

        deps[module][option] = {}

        for [f, arity] in fns
          deps[module][option][f] = str2nr(arity)
        endfor
      endif
    else
      deps[module] = {
        directive: directive,
        module: module
      }
    endif
  endfor

  return deps
enddef
