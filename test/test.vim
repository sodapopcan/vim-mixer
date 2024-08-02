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

function! GetBuf()
  let lines = []

  for lnr in range(1, line('$'))
    call add(lines, getline(lnr))
  endfor

  return lines
endfunction!

let fails = []
let fail_proto = {"file": "", "cmds": [], "cursor": []}

for file in readdir('tests')
  let file = join(readfile('./tests/'.file), "\n")
  let testdata = split(file, '#===')

  let buffer = split(testdata[0], "\n")
  let cases = testdata[1:]

  for lines in cases
    let instructions = ParseLines(split(lines, "\n"))

    for cursor in instructions.cursors
      new
      set ft=elixir

      call append(0, buffer)

      $d_
      call cursor(cursor)

      for cmd in instructions.cmds
        let cmd = escape(cmd, '<')
        exec cmd
      endfor

      if GetBuf() != instructions.expected
        let fail = copy(fail_proto)
        let fail.file = file
        let fail.cmds = instructions.cmds
        let fail.cursor = cursor
        call add(fails, fail)
      endif

      bwipe!
    endfor
  endfor
endfor

if len(fails)
  call writefile(['ya goofed'], '/dev/stderr', 'a')
  cquit!
else
  qall!
endif
