vim9script

export def Error(msg: string)
  redraw
  echohl ErrorMsg
  echomsg $'[mixer.vim] {msg}'
  echohl None
  v:errmsg = msg
enddef

export def Warn(msg: string)
  redraw
  echohl WarningMsg
  echomsg $'[mixer.vim] {msg}'
  echohl None
enddef

export def BufFocus(bufnr: number)
  const switchbuf_cached = &switchbuf
  set switchbuf=useopen
  exec 'sb ' .. bufnr
  exec 'set switchbuf=' .. switchbuf_cached
enddef

const MAPLIST = maplist()
  -> filter((_, v) => v.mode == 'n' && (v.rhs == 'K' || v.rhs == 'gd'))
  -> reduce((acc, v) => {
    acc[v.rhs] = v.lhs
    return acc
  }, {})

export def SetLocalMap(map: string, plug: string)
  if maparg(map, 'n') != '' && MAPLIST->has_key(map)
    exec 'nmap <buffer> ' .. MAPLIST[map] .. ' <Plug>(' .. plug .. ')'
  elseif maparg(map, 'n') == ''
    exec 'nmap <buffer> ' .. map .. ' <Plug>(' .. plug .. ')'
  endif
enddef

const PAIRS = {
  '(': ')',
  ')': '(',
  '{': '}',
  '}': '{',
  '[': ']',
  ']': '[',
}

export def GetPair(delim: string): string
  return get(PAIRS, delim, '')
enddef

export def Sub(str: string, pat: string, rep: string): string
  return substitute(str, pat, rep, '')
enddef

export def Gsub(str: string, pat: string, rep: string): string
  return substitute(str, pat, rep, 'g')
enddef

export def InList(list: list<any>, member: any): bool
  return index(list, member) != -1
enddef

export def FileExists(glob: string): bool
  return !empty(glob(glob))
enddef

export def RuntimeExists(file: string): bool
  return !empty(globpath(&rtp, file))
enddef

export def Matches(str: string, pat: string): bool
  return match(str, pat) >= 0
enddef

export def Glob(glob: string): list<string>
  return glob(glob, 0, 1)
enddef

export def IsBlank(string: string): bool
  return string =~ '^\s*$'
enddef

const IS_WIN = exists('+shellslash')
const SLASH = IS_WIN ? '\' : '/'

export def PathJoin(...paths: list<string>): string
  const path = join(paths, SLASH)

  return IS_WIN ? tr(path, '/', '\') : path
enddef

export def Unmapped(map: string, type: string): bool
  return empty(maparg(map, type))
enddef

export def ToElixirAlias(word: string): string
  return Sub(Camelcase(word), '^.', '\u&')
enddef

# Taken from @tpope's abolish.vim <https://github.com/tpope/vim-abolish>
export def Camelcase(w: string): string
  var word = Gsub(w, '-', '_')

  if word !~# '_' && word =~# '\l'
    return Sub(word, '^.', '\l&')
  else
    return Gsub(word, '\C\(_\)\=\(.\)', '\=submatch(1) == "" ? tolower(submatch(2)) : toupper(submatch(2))')
  endif
enddef

# Taken from @tpope's abolish.vim <https://github.com/tpope/vim-abolish>
export def Underscore(word: string): string
  return word
    -> Gsub('\.', '/')
    -> Gsub('\(\u\+\)\(\u\l\)', '\1_\2')
    -> Gsub('\(\l\|\d\)\(\u\)', '\1_\2')
    -> tolower()
enddef

# Taken from @tpope's rails.vim <https://github.com/tpope/vim-rails>
export def Singularize(word: string): string
  # Probably not worth it to be as comprehensive as Rails but we can
  # still hit the common cases.
  if word =~? '\.js$\|redis$' || empty(word)
    return word
  endif

  return word
    -> Sub('eople$', 'ersons')
    -> Sub('%([Mm]ov|[aeio])@<!ies$', 'ys')
    -> Sub('xe[ns]$', 'xs')
    -> Sub('ves$', 'fs')
    -> Sub('ss%(es)=$', 'sss')
    -> Sub('s$', '')
    -> Sub('%([nrt]ch|tatus|lias)\zse$', '')
    -> Sub('%(nd|rt)\zsice$', 'ex')
enddef

export def InRange(pos: list<number>, start: list<number>, end: list<number>): bool
  const [lnr, col] = pos
  const [start_lnr, start_col] = start
  const [end_lnr, end_col] = end

  if lnr > start_lnr && lnr < end_lnr
    return true
  endif

  if lnr == start_lnr && lnr == end_lnr
    return col >= start_col && col <= end_col
  endif

  if lnr == start_lnr && col >= start_col
    return true
  endif

  if lnr == end_lnr && col <= end_col
    return true
  endif

  return false
enddef
