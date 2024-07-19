source t/_helpers.vim

silent filetype plugin indent on
syntax enable

set cpo&vim

describe 'a do/end block text object'
  before
    new
    set filetype=elixir
  end

  after
    close!
    let @" = ""
  end


  context "outside a module"
    it 'deletes a block with the cursor before the do'
      let code =
      \ Append(['if condition? do',
      \         '  "true"',
      \         'end'])
      call Setpos(1, 1)

      normal dad

      Expect @" == code
    end

    it 'deletes a block with the cursor inside'
      let code =
      \ Append(['if condition? do',
      \         '  "true"',
      \         'end'])
      call Setpos(2, 3)

      normal dad

      Expect @" == code
    end
  end

  context "multiline function heads"
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

  context "with"
    it 'deletes a single-clause with'
      let code =
      \ Append(['defmodule Foo do(',
      \         '  def foo do',
      \         '    with {:ok, foo} <- foo() do',
      \         '      foo',
      \         '    end',
      \         '  end',
      \         'end'])
      call Setpos(3, 5)

      normal dad

      Expect @" == JoinNL(['    with {:ok, foo} <- foo() do',
      \                    '      foo',
      \                    '    end'])
    end
  end
end
