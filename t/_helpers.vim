function! Fixture(file)
  let fname = "t/".a:file
  let code = join(readfile(fname), "\n")
  let [code, buffer, reg] = split(code, '#.#\n')

  call append(0, split(code, "\n"))

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
