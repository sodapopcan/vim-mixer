runtime! plugin/elixir-mix.vim
source t/_helpers.vim

silent filetype plugin indent on
syntax enable

describe 'single line blocks'
  before
    new
    set filetype=elixir
  end

  after
    close!
    let @@ = ""
  end


  it 'deletes a block with the cursor before the do'
    let code =
    \ Append(['if condition? do',
    \         '  "true"',
    \         'end'])
    1
    normal! ^

    normal dad

    Expect @" == code
  end
end

describe 'multi-line blocks'
  it 'deletes when block'
    let code =
    \ Append(['some_fun(',
    \         '  %{hi: "hi!"},',
    \         '  %{eq: "="},',
    \         '  another_arg',
    \         ') do',
    \         '  some("body")',
    \         'end'])
    call Setpos(5, 3)

    normal dad

    Expect @" == code
  end

  it 'deletes multi-line map'
    let code =
    \ Append(['hello %{',
    \         '  hi: "hi"',
    \         '} do',
    \         '  "true"',
    \         'end'])
    call Setpos(3, 3)

    normal dad

    Expect @" == code
  end
end
