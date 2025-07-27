vim9script

import autoload './util.vim'
import autoload './cursor.vim' as cur
import autoload './project.vim'

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

const MAX_USE_RECURSION = 2

const ELIXIR_PATH = project.GetElixirPath()

const KERNEL_FNS = readfile(ELIXIR_PATH .. '/kernel.ex')
  -> matchstrlist('^\s*def\%(macro\|delegate\)\= \zs\k\+\ze')
  -> map((_, match) => match.text)
  -> uniq()

export def GotoDefinition(): void
  const target = cur.Target()

  const [grep_regex, vim_regex] = BuildRegex(target)

  if JumpToLocal(target, vim_regex)
    return
  endif

  const directives = ResolveDirectives(target, expand('%'))

  var [modules, results] = GetModulesAndResults(target, directives, grep_regex)

  const module_regex = BuildModuleRegex(modules)

  var filtered_results: list<any> = []

  if len(results) > 1
    filtered_results = results
      -> copy()
      -> map((_, f) => [readfile(f), f])
      -> map((_, f) => [matchstrlist(f[0], module_regex), FindDef(f[0], vim_regex), f[1]])
      -> filter((_, f) => !f[0]->empty() && f[1] != 0)
      -> sort((a, b) => a[2] > b[2] ? 1 : -1)
      -> map((_, f) => [f[2], f[1]])
  else
    filtered_results = results
      ->copy()
      ->map((_, f) => [f, FindDef(readfile(f), vim_regex)])
  endif

  if len(filtered_results) == 1
    const [file, line] = filtered_results[0]

    var cmd: string
    if file =~# '^' .. b:mix_project.root .. '/lib' ||
        file =~# '^' .. b:mix_project.root .. '/test'
      cmd = 'edit +' .. line
    else
      cmd = 'silent view +' .. line .. '|set\ bufhidden=delete'
    endif

    exec cmd file
    normal! zz^
  elseif len(filtered_results) == 0
    echomsg 'Nothing found'
  else
    const list_contents = filtered_results
      -> copy()
      -> map((_, f) => {
        return {
          filename: f[0],
          lnum: f[1],
          text: readfile(f[0])[f[1] - 1]}
        }
      )

    const list_type = get(g:, 'mixer_jump_to_definition_multi_result_list', 'qflist')

    if list_type == 'qflist'
      setqflist(list_contents)
      botright copen
    elseif list_type == 'loclist'
      setloclist(0, list_contents)
      lopen
    endif
  endif
enddef

def JumpToLocal(target: dict<any>, vim_regex: string): bool
  if !target.is_delegate
    return v:false
  endif

  const view = winsaveview()

  search('defmodule', 'bW', 0, 0, cur.OnStringOrComment)
  const line = search(vim_regex, 'Wn', 0, 0, cur.OnStringOrComment)
  winrestview(view)

  if line != 0
    exec 'normal!' line .. 'gg^'

    return v:true
  endif

  return v:false
enddef

def BuildRegex(target: dict<any>): list<string>
  var grep_regex: string
  var vim_regex: string

  # If the function ends with a `?` or `!`, we need to account for that.
  var flair = matchstr(target.fn, '[!?]$')
  var bare = target.fn

  if !empty(flair)
    bare = target.fn[: -2]
  endif

  if cur.OnHEEx()
    grep_regex = "'\\s*def(macro|delegate)*?p*? \\<" .. bare .. "\\>" .. (flair) .. "\(.*assigns.*\)'"
    vim_regex = '^\s*def\%(macro\|delegate\)\=p\= \<' .. bare .. flair .. '\>(.*assigns.*)'
  else
    grep_regex = "'\\s*def(macro|delegate)*?p*? \\<" .. bare .. "\\>" .. flair .. "'"
    vim_regex = '^\s*def\%(macro\|delegate\)\=p\= \<' .. bare .. flair .. '\>'
  endif

  return [grep_regex, vim_regex]
enddef

def Grep(cmd: string, paths: list<string> = []): list<string>
  const search_paths = paths
    -> copy()
    -> map((_, path) => path =~# '^\/' ? path : b:mix_project.root .. '/' .. path)
    -> join(' ')

  const results = systemlist("rg -l --type elixir " .. cmd .. ' ' .. search_paths)

  if v:shell_error > 0
    return []
  else
    return results
  endif
enddef

def GetModulesAndResults(target: dict<any>, directives: dict<any>, grep_regex: string): list<list<string>>
  var modules: list<string> = []
  var results: list<string> = []

  if !empty(target.alias)
    var module: string = target.alias

    if has_key(directives, target.alias_prefix)
      module = directives[target.alias_prefix].module
      modules = [module]
    else
      modules = [target.alias]
    endif

    if project.IsProjectModule(module)
      results = Grep(grep_regex, ["lib", "test"])
    elseif util.InList(BUILTINS, target.alias)
      results = Grep(grep_regex, [ELIXIR_PATH])
    else
      results = Grep(grep_regex, ["deps/**/lib/*"])
    endif
  else
    # Function is unqualified
    if util.InList(KERNEL_FNS, target.fn)
      results = Grep(grep_regex, [ELIXIR_PATH .. '/kernel.ex'])
    else
      modules = directives
        -> copy()
        -> filter((_, v) => v.directive !=# 'alias')
        -> map((_, v) => v.module)
        -> values()

      results = Grep(grep_regex, ["lib", "test", "deps/**/lib/*"])
    endif
  endif

  return [modules, results]
enddef

def BuildModuleRegex(modules: list<string>): string
  var module_regex_list: list<string> = []

  for module in modules
    const m = module->split('\.')

    const submodules_regex = m[1 : ]
      -> map((_, a) => '\%(\.\|\_.*defmodule\s\+\)' .. a)
      -> join('')

    module_regex_list->add('\%(^\s*defmodule\s\+' .. m[0] .. submodules_regex .. '\s\+do\)')
  endfor

  return module_regex_list->join('\|')
enddef

class Context
  var skip: bool
  var in_module: bool
  var module_end: string
  var in_heredoc: bool
  var heredoc_end: string
  var heredoc_delim: string
  var _keep: bool

  def new()
    this.skip = v:true
    this.in_module = v:false
    this.in_heredoc = v:false
    this._keep = v:false
  enddef

  def Track(line: string, module: string = '')
    const heredoc = matchlist(line, '\(\s*\).*\("""\|''''''\)$')

    if len(heredoc) > 0
      this.heredoc_delim = heredoc[2]
      this.heredoc_end = '^' .. heredoc[1] .. this.heredoc_delim .. '$'
      this.in_heredoc = v:true
    endif

    if !this.skip && len(heredoc) > 0
      this.skip = v:true
      this.in_heredoc = v:true
    elseif this.skip && (line =~ this.heredoc_end)
      this.skip = v:false
      this.in_heredoc = v:false
      this.heredoc_end = ''
      this.heredoc_delim = ''
    endif

    if module !=# '' && !this.in_heredoc
      const module_match = matchlist(line, '^\(\s*\)defmodule\s\+' .. module .. '\s\+do')

      if !this.in_module && module_match != []
        this.skip = v:false
        this.in_module = v:true
        this.module_end = '^' .. module_match[1] .. 'end$'
      elseif this.in_module && line =~# this.module_end
        this.in_module = v:false
        this.skip = v:true
      endif
    endif
  enddef
endclass

def FindDef(lines: list<string>, regex: string): number
  var line_num = 0
  var context = Context.new()

  for line in lines
    line_num += 1

    context.Track(line)

    if context.skip || line =~ '^\s*#'
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

def ResolveDirectives(target: dict<any>, filename: string): dict<any>
  # This function parses all of the `import`, `require`, `alias` directives.
  # It does it in two passes, mainly to deal with multi-liners.
  # First it accumulates any matching line into a list.  In the case of
  # a multi-line, it will append to the last element of the list until it finds
  # a terminating character, which is either a `}` or a `]`.  It deals with
  # shorthands like `import Foo.{Bar, Baz}` and `alias Foo.{Bar, Baz}` even
  # if they are multi-line.
  #
  # Afterwards, it maps the accumulator into a dictionary in the form of:
  #
  #   {
  #     'MyAlias': {
  #       module: 'Full.Module.MyAlias',
  #       directive: 'import',
  #       only: {
  #         foo: 3,
  #         bar: 1,
  #         bar: 2
  #       }
  #     }
  #   }
  #
  final directives = {}

  for line in FindDirectives(target, filename, 1)
    const [full, directive, module, _, _, _, _, _, _, _] = matchlist(line, DIRECTIVE_REGEX)

    const expandables = matchstr(line, '{\zs.*\ze}')

    if !empty(expandables)
      for alias in expandables->split(',')->map((_, v) => trim(v))
        directives[alias] = {directive: directive, module: module .. alias} 
      endfor
    elseif directive == 'alias'
      if line =~# 'as:\s\+\k\+'
        const alias = matchstr(line, 'as:\s\+\zs\k\+')

        directives[alias] = {directive: directive, module: module}
      else
        const alias = module->split('\.')[-1]

        directives[alias] = {directive: directive, module: module}
      endif
    elseif directive == 'import' && line =~# 'only:\|except:'
      directives[module] = {
        directive: directive,
        module: module
      }

      const matches = matchlist(line, '\(only:\|except:\) \[\zs.*\ze\]')

      if len(matches) > 0
        const fns = matches[0]->split(',')->map((_, v) => v->split(': '))
        const option = matches[1]

        directives[module][option] = {}

        for [f, arity] in fns
          directives[module][option][f] = str2nr(arity)
        endfor
      endif
    else
      directives[module] = {
        directive: directive,
        module: module
      }
    endif
  endfor

  return directives
enddef

const MAPPING = {'{': '}', '[': ']'}

def FindDirectives(target: dict<any>, filename: string, recursion_count: number): list<string>
  const context = Context.new()
  final directives: list<string> = []
  var multi_close = '' # '}' or ']'
  const lines = readfile(filename)

  for line in lines
    context.Track(line, target.context_alias)

    if context.skip || line =~# '^\s*#'
      continue
    endif

    # TODO: We need to be smarter about looking in `__using__` if we're in
    # a `use` as well as looking in the whole module if it imports itself.
    const type = matchstr(line, '^\s*\zs\%(\<use\>\|\<import\>\|\<require\>\|\<alias\>\)\ze')

    if !empty(type)
      if type == 'use' && recursion_count != MAX_USE_RECURSION
        const module = matchstr(line, '^\s*use\s\+\zs[[:alnum:]\.]\+')
        const files = Grep("'defmodule " .. module .. " do'",  ["lib", "test", "deps/**/lib/*"])
        const results = FindDirectives(target, files[0], recursion_count + 1)

        for result in results
          directives->add(result)
        endfor
      else
        const open = matchstr(line, '{\|\[')

        if type !=# 'use' && !empty(open) && line !~# MAPPING[open]
          multi_close = MAPPING[open]
        endif

        directives->add(trim(line))
      endif
    elseif !empty(multi_close)
      if line =~# multi_close .. '$'
        multi_close = ''
      endif

      directives[-1] = directives[-1] .. trim(line)
    endif
  endfor

  return directives
enddef
