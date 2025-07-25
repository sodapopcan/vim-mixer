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
  # The target is either a function or an alias.
  # It returns {fn: string, alias: string} which may look like:
  #   {fn: 'some_function', alias: 'My.Module'}
  const target = cur.Target()

  const [grep_regex, vim_regex] = BuildRegex(target)

  # If the function is defined in the current file, then we can just jump to it
  # and we're done.
  if JumpToLocal(target, vim_regex)
    return
  endif

  # All right, so we're dealing with a remote function.  In order to resolve
  # where it is defined, we're going to have parse the `alias`, `require`,
  # `import` and, unforunately (although I love it), `use` directives.  However,
  # we dont' have to alway worry about all of them.  If our target is qualified,
  # this means we only have to concern ourselves with `alias` and `require`, and
  # it'll actually be pretty easy to find!  If our function is happens to be
  # included in the `:only` option of an import, then that's really best case
  # scenario!  If we're dealing with a naked `import`, that's where it gets
  # trickier, but it's not so bad.  We can grep for our function definition and
  # use the imported module names to narrow down the search. 
  # now we gotta start grepping to figure out where our function or alias is
  # defined.  To do this, we're going to need to parse all of the `require`,
  # `import`, and `alias` directives in the current file.  If there is a `use`
  # then we're going to have jump into that and parse that as well.

  const directives = ResolveDirectives(expand('%'))

  var modules: list<string> = []
  var results: list<string> = []

  if !empty(target.alias)
    var module: string = target.alias

    if has_key(directives, target.alias)
      module = directives[target.alias].module
      modules = [module]
    else
      modules = [target.alias]
    endif

    if project.IsProjectModule(module)
      results = Grep(grep_regex, ["lib", "test"])
    elseif util.InList(BUILTINS, target.alias)
      results = Grep(grep_regex, [ELIXIR_PATH])
    else
      results = Grep(grep_regex, ["deps/*"])
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

      results = Grep(grep_regex, ["lib", "test", "deps/*"])
    endif
  endif

  const module_regex = '^\s*defmodule\s\+\%(' .. join(modules, '\|') .. '\)\s\+do'

  var filtered_results: list<string> = []

  if len(results) > 1
    filtered_results =
      results
      ->copy()
      ->filter((_, f) => !matchstrlist(readfile(f), module_regex)->empty())
  else
    filtered_results = results
  endif

  if len(filtered_results) > 0
    const file = filtered_results[0]
    const line = FindDef(readfile(file), vim_regex)
    var cmd: string
    if file =~# '^' .. b:mix_project.root .. '/lib' ||
        file =~# '^' .. b:mix_project.root .. '/test'
      cmd = 'edit +' .. line
    else
      cmd = 'silent keepjumps view +' .. line .. '|set\ bufhidden=delete'
    endif

    exec cmd file
    normal! zz^
  endif
enddef

def JumpToLocal(target: dict<string>, vim_regex: string): bool
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

def BuildRegex(target: dict<string>): list<string>
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

class Context
  var in_docstring: bool
  var indent: number
  var delim: string

  def new()
    this.in_docstring = v:false
  enddef

  def Track(line: string)
    const match = matchlist(line, '\(\s*\).*\("""\)\|\(''''''\)')

    if len(match) > 0
      this.indent = match[1]->len()
      this.delim = match[2]
    endif

    if !this.in_docstring && len(match) > 0
      this.in_docstring = v:true
    elseif this.in_docstring && (line =~ '^\s\{' .. this.indent .. '\}' .. this.delim)
      this.in_docstring = v:false
      this.indent = 0
      this.delim = ''
    endif
  enddef
endclass

def FindDef(lines: list<string>, regex: string): number
  var line_num = 0
  var context = Context.new()

  for line in lines
    line_num += 1

    context.Track(line)

    if context.in_docstring || line =~ '^\s*#'
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

def ResolveDirectives(filename: string): dict<any>
  # This function parses all of the `import`, `require`, `alias` directives.
  # It does it in two passes, mainly to deal with multi-liners.
  # First it accumulates any matching line into a list.  In the case of
  # a multi-line, it will append to the last element of the list until it finds
  # a terminating character, which is either a `}` or a `]`.  It deals with
  # shorthands like `import Foo.{bar, baz}` and `alias Foo.{bar, baz}` whether
  # they be multi-line or single-line.
  #
  # Afterwards, it maps the accumulator into a dictionary in the form of:
  #
  #   {
  #     'Alias': {
  #       module: 'Full.Module.Alias',
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

  for line in FindDirectives(filename, 1)
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

def FindDirectives(filename: string, recursion_count: number): list<string>
  const context = Context.new()
  final directives: list<string> = []
  var multiend = '' # '}' or ']'
  const lines = readfile(filename)

  for line in lines
    context.Track(line)

    if context.in_docstring || line =~# '^\s*#'
      continue
    endif

    const type = matchstr(line, '^\s*\zs\%(\<use\>\|\<import\>\|\<require\>\|\<alias\>\)\ze')

    if !empty(type)
      if type == 'use' && recursion_count != MAX_USE_RECURSION
        const module = matchstr(line, '^\s*use\s\+\zs[[:alnum:]\.]\+')
        const files = Grep("'defmodule " .. module .. " do'",  ["./lib", "./test", "./deps/*"])
        const results = FindDirectives(files[0], recursion_count + 1)

        for result in results
          directives->add(result)
        endfor
      else
        const open = matchstr(line, '{\|\[')

        if type !=# 'use' && !empty(open) && line !~# MAPPING[open]
          multiend = MAPPING[open]
        endif

        directives->add(trim(line))
      endif
    elseif !empty(multiend)
      if line =~# multiend .. '$'
        multiend = ''
      endif

      directives[-1] = directives[-1] .. trim(line)
    endif
  endfor

  return directives
enddef
