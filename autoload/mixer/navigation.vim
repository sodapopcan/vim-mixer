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
  # The target is either a function or an alias.
  # It returns {fn: string, alias: string} which may look like:
  #   {fn: 'some_function', alias: 'My.Module'}
  const target = FindTarget()

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
  #
  # We're going to deal with the `use` directives upfront since it's a little
  # easier to reason about.  Unlike the others, `use` is able to inject
  # functions that aren't necessarily defined in the `use`d module itself.

  final deps = {}

  var view = winsaveview()

  try
    search('defmodule', 'bW', 0, 0, cur.OnStringOrComment)

    while search('^\s*\<use\>', 'W', 0, 0, cur.OnStringOrComment) != 0
      const l = getline('.')
      const mod = matchstr(l, '^\s*\<use\>\s\+\zs\%(\k\|\.\)\+')
      # TODO: Check if it's actually a project module.
      if mod =~# b:mix_project.namespace
        const res = Grep("'defmodule " .. mod .. " do' ./lib ./test")

        deps->extend(ResolveDeps(readfile(res[0])))
      else
        # If the `use` is coming from a dependency, we're not going to read it
        deps[mod] = {directive: 'use', module: mod}
      endif
    endwhile
  finally
    winrestview(view)
  endtry

  deps->extend(ResolveDeps(readfile(expand('%'))))

  var module: string
  if has_key(deps, target.alias)
    module = deps[target.alias].module
  endif

  var results = Grep(grep_regex)

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
    results = Grep(grep_regex .. " ./deps")

    if len(results) > 0
      HandleResults(results, vim_regex, v:false)
    endif
  endif
enddef

# Target is the word under the cursor, which may be a function or an alias.
# It returns a dictionary of the alias and optionally the function name.
def FindTarget(): dict<string>
  var fn = expand('<cword>')
  final aliases: list<string> = []

  # While <cexpr> works beautifully in Elixir files, it does not work in HEEx
  # files, so we have to do this manually.
  const view = winsaveview()

  try
    # Move to the beginning of the word.
    normal! wb

    if cur.Char(col('.') - 2) != '<'
      const curr_line_num = line('.')

      while cur.Char(col('.') - 1) == '.' && line('.') == curr_line_num
        normal! bb
        aliases->add(expand('<cword>'))
      endwhile
    endif

    return {
      fn: fn,
      alias: aliases->join('.')
    }
  catch
    winrestview(view)
    return {}
  endtry
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

    if flair == '?'
      flair = '\?'
    endif
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

class Context
  var in_docstring: bool
  var DOCSTRING_START_REGEX = '^\s*\%(\%(@\k\+\s\)\|\~\k\+\)"""\|'''''''
  var DOCSTRING_END_REGEX = '^\s*"""\|'''''''

  def new()
    this.in_docstring = v:false
  enddef

  def Track(line: string)
    if line =~ this.DOCSTRING_START_REGEX
      this.in_docstring = v:true
    elseif line =~ this.DOCSTRING_END_REGEX
      this.in_docstring = v:false
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

def ResolveDeps(lines: list<string>): dict<any>
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
  final deps = {}

  for line in FindDirectives(lines)
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

def FindDirectives(lines: list<string>): list<string>
  const context = Context.new()
  const MAPPING = {'{': '}', '[': ']'}
  final directives: list<string> = []
  var multiend = '' # '}' or ']'

  for line in lines
    context.Track(line)

    if context.in_docstring || line =~# '^\s*#'
      continue
    endif

    const type = matchstr(line, '^\s*\%(\<import\>\|\<require\>\|\<alias\>\)')

    if !empty(type)
      const open = matchstr(line, '{\|\[')

      if type != 'use' && !empty(open) && line !~# MAPPING[open]
        multiend = MAPPING[open]
      endif

      directives->add(trim(line))
    elseif !empty(multiend)
      if line =~# multiend .. '$'
        multiend = ''
      endif

      directives[-1] = directives[-1] .. trim(line)
    endif
  endfor

  return directives
enddef

# TODO: To make this better we should check that either there is both
# a lib/foo directory and either a lib/foo.ex or lib/foo/foo.ex file.
def GetProjectRoots(): list<string>
  return glob('lib/*', 0, 1)
    -> filter((_, f) => f !~# '\.' || f =~# '\.ex\|\.exs$')
    -> map((_, f) => fnamemodify(f, ':t:r'))
    -> filter((_, f) => f != 'mix')
    -> uniq()
    -> map((_, f) => util.ToElixirAlias(f))
enddef
