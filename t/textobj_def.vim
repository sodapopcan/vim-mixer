runtime! plugin/elixir-mix.vim

silent filetype plugin indent on
syntax enable

describe "def textobj"
  before
    new
    set filetype=elixir
  end

  after
    close!
  end

  it "deletes an empty function on col 1"
    let code = ['def foo do'
               \'end']
    call append(0, code)
    1

    normal daf

    Expect @" == join(code, "\n")."\n"
  end

  it 'delete an indented empty function with the cursor on d'
    let code = ['  def foo do',
               \'  end']
    call append(0, code)
    1
    normal! w

    normal daf

    Expect @" == join(code, "\n")."\n"
  end

  it 'delete an indented empty function with the cursor outside d'
    let code = ['  def foo do',
               \'  end']
    call append(0, code)
    1
    normal! 0

    normal daf

    Expect @" == join(code, "\n")."\n"
  end
end
