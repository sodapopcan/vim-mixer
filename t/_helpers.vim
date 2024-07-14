function! Append(code)
  call append(0, a:code)
  normal! Gd_

  return Join(a:code)
endfunction

function! AppendNL(code)
  call append(0, a:code)

  return Join(a:code)
endfunction

function! AppendAt(at, code)
  call append(a:at, a:code)
  normal! Gd_

  return Join(a:code)
endfunction

function! AppendAtNL(at, code)
  call append(a:at, a:code)

  return Join(a:code)
endfunction

function! Join(code)
  return join(a:code, "\n")
endfunction

function! Setpos(lnr, col)
  call setpos('.', [bufnr('%'), a:lnr, a:col, 0])
endfunction
