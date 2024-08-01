function! ParseLines(lines)
  let instructions = {"cmds": [], "cursors": [], "expected": []}

  for line in a:lines
    if line =~ '^#\~'
      call add(instructions.cmds, trim(matchstr(line, '^#\~\zs.*')))
    elseif line =~ '^#\.'
      let line = matchstr(line, '^#\.\zs.*')
      let data = split(line, ',')
      let cursor = map(data, {-> str2nr(v:val)})
      call add(instructions.cursors, cursor)
    elseif line =~ '^#'
      " skip
    else
      call add(instructions.expected, line)
    endif
  endfor

  return instructions
endfunction!

" function! GetBuf()
"   let lines = []

"   for lnr in range(1, line('$'))
"     call add(getline(lnr))
"   endfor

"   return lines
" endfunction!

for file in readdir('tests')
  let file = join(readfile('./tests/'.file), "\n")
  let testdata = split(file, '#===')

  let buffer = split(testdata[0], "\n")
  let cases = testdata[1:]

  for lines in cases
    let instructions = ParseLines(split(lines, "\n"))

    new
    set ft=elixir
    call append(0, buffer)
    for cursor in instructions.cursors
      call cursor(cursor)

      for cmd in instructions.cmds
        exec cmd
      endfor
    endfor
  endfor


  " let cursor_pos = split(testdata[1], "\n")
  " let cursor_pos = map(cursor_pos, {-> substitute(v:val, '# ', '', '')})
  " let cursor_pos = map(cursor_pos, {-> map(split(v:val, " "), {-> str2nr(v:val)})})

  " for test in testdata[2:]
  "   let lines = split(test, "\n")
  "   let cmd = lines[0][2:]
  "   let lines = lines[1:]
  "   let lines = map(lines, {-> substitute(v:val, '^#nl', '', '')})
  "   let lines = map(lines, {-> substitute(v:val, '^#keep\s', '', '')})
  "   let cases = split(join(lines, "\n"), "#\"\n")
  "   " let cases = map(cases, {-> v:val == "" ? v:val."\n" : v:val})

  "   let n = 0

  "   for case in cases
  "     for [lnr, col] in cursor_pos
  "       new
  "       set ft=elixir
  "       call append(0, setup)
  "       call setpos('.', [0, lnr, col, 0])
  "       exec "normal" cmd

  "       if $DEBUG
  "         Debug join([a:1, cmd, 'iter:', n, 'lnr:', lnr, 'col:', col], ' ')
  "       endif

  "       if n == 0
  "         Expect Buffer() == cases[0]
  "       else
  "         Expect @" == cases[1]
  "       endif

  "       close!
  "     endfor

  "     let n = 1
  "   endfor
  " endfor
endfor

" qa!
