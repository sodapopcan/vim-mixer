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
  const token = expand('<cword>')

  if token =~# '^\u'
    return
  endif

  var qualified: list<string>

  # While <cexpr> works beautifully in Elixir files, it does not work in HEEx
  # files, so here we are.
  final aliases: list<string> = []

  # Move back to the start of the word.
  normal! wb

  const fn = expand('<cword>')

  if cur.Char(col('.') - 2) != '<'
    const curr_line_num = line('.')
    while cur.Char(col('.') - 1) == '.' && line('.') == curr_line_num
      normal! bb
      aliases->add(expand('<cword>'))
    endwhile
  endif

  var rg_regex: string
  var vim_regex: string

  if cur.OnHEEx()
    rg_regex = "'\s*def(macro)*?p*? \\<" .. shellescape(fn) .. "\\>\(.*assigns.*\)'"
    vim_regex = '^\s*def\%(macro\)\=p\= \<' .. fn .. '\>(.*assigns.*)'
  else
    rg_regex = "'\s*def(macro)*?p*? \\<" .. shellescape(fn) .. "\\>'"
    vim_regex = '^\s*def\%(macro\)\=p\= \<' .. fn .. '\>'
  endif

  const view = winsaveview()
  normal! gg
  const line = search(vim_regex, 'Wn', 0, 0, () => cur.OnStringOrComment())
  winrestview(view)

  if line != 0
    exec 'normal!' line .. 'gg^'

    return
  endif

  var results = Grep(rg_regex)

  const deps = ResolveDeps(readfile(expand('%')))

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
  const project_namespace = b:mix_project.namespace

  var docstring = DocString.new()
  var multiend = '' # '}' or ']'

  final deps = {}
  final accumulator: list<string> = []

  for line in lines
    docstring.Update(line)

    if docstring.in || line =~# '^\s*#'
      continue
    endif

    const type = matchstr(line, '^\s*\%(\<use\>\|\<import\>\|\<require\>\|\<alias\>\)')

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

  return {}
enddef
