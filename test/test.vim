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
let fail_proto = {"file": "", "lnr": 0, "message": "", "cmds": [], "cursor": []}

for file in readdir('tests')
  let contents = join(readfile('./tests/'.file), "\n")
  let testdata = split(contents, '#@@@')

  let buffer = split(testdata[0], "\n")
  let cases = testdata[1:]
  let lnr = len(buffer)

  for lines in cases
    let instructions = ParseLines(split(lines, "\n"))
    let lnr += len(instructions)

    for cursor in instructions.cursors
      let lnr += len(instructions)

      new
      set ft=elixir

      call append(0, buffer)

      $d_
      call cursor(cursor)

      for cmd in instructions.cmds
        let cmd = escape(cmd, '<')
        exec cmd
      endfor

      let expected = instructions.expected

      if GetBuf() != expected
        let fail = copy(fail_proto)
        let fail.file = file
        let fail.lnr = lnr
        let fail.message = getline(lnr + 1)
        let fail.cmds = instructions.cmds
        let fail.cursor = cursor
        call add(fails, fail)
      endif

      bwipe!
    endfor
  endfor
endfor

if len(fails)
  let output = map(fails, {-> v:val.file.":".v:val.lnr." ".v:val.message})
  call writefile(output, 'fails')
  cquit!
else
  qall!
endif
