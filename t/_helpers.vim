function! Fixture(file)
  let fname = "t/".a:file
  let code = join(readfile(fname), "\n")
  let [code, buffer, reg] = split(code, '#.#\n')

  call append(0, split(code, "\n"))

  let reg = split(reg, "\n")

  if reg[-1] =~ "^#nl"
    let reg[-1] = ""
  endif

  let reg = join(reg, "\n")

  return {"code": code, "buffer": buffer, "reg": reg}
endfunction

function! Append(code)
  call append(0, a:code)
  normal! $d_

  return Join(a:code)
endfunction

function! AppendNL(code)
  call append(0, a:code)

  return Join(a:code)
endfunction

function! AppendAt(at, code)
  call append(a:at, a:code)
  normal! $d_

  return Join(a:code)
endfunction

function! AppendAtNL(at, code)
  call append(a:at, a:code)

  return Join(a:code)
endfunction

function! Join(code)
  return join(a:code, "\n")
endfunction

function! JoinNL(code)
  return Join(a:code)."\n"
endfunction

function! Setpos(lnr, col)
  call setpos(".", [0, a:lnr, a:col, 0])
endfunction

function! Buffer()
  return join(getline(1, '$'), "\n")
endfunction

command! -nargs=* Cursor call Cursor(<f-args>)

function! Cursor(...)
  call setpos(".", [0, a:1, a:2, 0])
endfunction

command! -nargs=* ExpectCursor call ExpectCursor(<f-args>)

function! ExpectCursor(...)
  Expect [str2nr(a:1), str2nr(a:2)] == [line('.'), col('.')]
endfunction


