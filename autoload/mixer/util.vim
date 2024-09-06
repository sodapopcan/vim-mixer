vim9script

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

# export def IsBlank(line = ''): bool
#   if line
#     return line =~ '^\s*$'
#   else
#     return getline('.') =~ '^\s*$'
# enddef

export def Unmapped(map: string, type: string): bool
  return empty(maparg(map, type))
enddef

export def ToElixirAlias(word: string): string
  return Sub(Camelcase(word), '^.', '\u&')
enddef

# Taken from @tpope's abolish.vim <http//github.com/tpope/vim-abolish>
export def Camelcase(w: string): string
  var word = Gsub(w, '-', '_')

  if word !~# '_' && word =~# '\l'
    return Sub(word, '^.', '\l&')
  else
    return Gsub(word, '\C\(_\)\=\(.\)', '\=submatch(1) == "" ? tolower(submatch(2)) : toupper(submatch(2))')
  endif
enddef

export def InRange(pos: list<number>, start: list<number>, end: list<number>): bool
  var [lnr, col] = pos
  var [start_lnr, start_col] = start
  var [end_lnr, end_col] = end

  if lnr > start_lnr && lnr < end_lnr
    return 1
  endif

  if lnr == start_lnr && lnr == end_lnr
    return col >= start_col && col <= end_col
  endif

  if lnr == start_lnr && col >= start_col
    return 1
  endif

  if lnr == end_lnr && col <= end_col
    return 1
  endif

  return 0
enddef
