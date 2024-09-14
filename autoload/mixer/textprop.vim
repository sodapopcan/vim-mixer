vim9script

import './util.vim'

export def Ensure(type: string, props: dict<any>)
  if !util.InList(prop_type_list(extend({type: type}, copy(props))), type)
    prop_type_add(type, props)
  endif
enddef

export def Multi(type: string, bufnr: number, start_lnr: number, end_lnr: number)
  prop_add(start_lnr, 1, {
    bufnr: bufnr,
    type: type,
    end_lnum: end_lnr,
    end_col: len(getline(end_lnr)) + 1
  })
enddef

export def Remove(type: string, bufnr: number)
  prop_remove({type: type, bufnr: bufnr})
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
