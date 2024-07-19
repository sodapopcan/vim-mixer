command! -nargs=1 TestTextObject call TestTextObject(<f-args>)

function! TestTextObject(...)
  let fname = "t/".a:1
  let file = join(readfile(fname), "\n")
  let testdata = split(file, '#_')

  let setup = split(testdata[0], "\n")

  let cursor_pos = split(testdata[1], "\n")
  let cursor_pos = map(cursor_pos, {-> substitute(v:val, '# ', '', '')})
  let cursor_pos = map(cursor_pos, {-> map(split(v:val, " "), {-> str2nr(v:val)})})

  for test in testdata[2:]
    let lines = split(test, "\n")
    let cmd = lines[0][2:]
    let cases = split(join(lines[1:], "\n"), "#\"\n")

    let n = 0

    for case in cases
      for [lnr, col] in cursor_pos
        new
        set ft=elixir
        call append(0, setup)
        call setpos('.', [0, lnr, col, 0])
        exec "normal" cmd

        if n == 0
          Expect Buffer() == cases[0]
        else
          Expect @" == cases[1]."\n"
        endif

        close!
      endfor

      let n = 1
    endfor
  endfor
endfunction

function! Fixture(file)
  let fname = "t/".a:file
  let code = join(readfile(fname), "\n")
  let [code, buf_a, buf_i, reg_a, reg_i] = split(code, '#..#\n')

  call append(0, split(code, "\n"))

  let reg = split(reg, "\n")

  if reg[-1] =~ "^#nl"
    let reg[-1] = ""
  endif

  let reg = join(reg, "\n")

  return {"code": code, "a": a, "i", i, "reg": reg}
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

" command! -nargs=0 Setup call Setup()

" function! Setup()
" endfunction
