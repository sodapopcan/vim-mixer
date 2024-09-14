vim9script

export def Ensure(name: string)
  if empty(prop_type_get(name))
    prop_type_add(name, {})
  endif
enddef

export def Multi(type: string, start_lnr: number, end_lnr: number)
  prop_add(start_lnr, 1, {
    type: type,
    end_lnum: end_lnr,
    end_col: len(getline(end_lnr)) + 1
  })
enddef

export def Remove(opts: dict<any>)
  prop_remove(opts)
enddef

export def GetLines(type: string): list<string>
  final lines = []

  for prop in prop_list(1, {end_lnum: line('$')})
    if prop.type == type
      add(lines, getline(prop.lnum))
    endif
  endfor

  return lines
enddef
