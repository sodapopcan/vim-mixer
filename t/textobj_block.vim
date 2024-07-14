runtime! plugin/elixir-ext.vim
source t/_helpers.vim

silent filetype plugin indent on
syntax enable


describe 'Block'
  before
    new
    set filetype=elixir
  end

  after
    close!
  end

  it 'deletes inside block with the cursor before the do'
    let code = ['if condition? do',
               \'  "true"',
               \'end']
    call append(0, code)
    1
    normal! ^

    normal die

    Expect @@ == '  "true"'
  end

  it 'deletes inside block with the cursor inside it'
    let code = ['if condition? do',
               \'  "true"',
               \'end']
    call append(0, code)
    2
    normal! ^

    normal die

    Expect @@ == '  "true"'
  end

  it 'in a nested block, delete outer if not in inner'
    let code = ['if condition? do',
               \'  foo = "bar"',
               \'',
               \'  if foo == "bar" do',
               \'    "baz"',
               \'  end',
               \'end']
    call append(0, code)
    2
    normal! ^

    normal die

    Expect @@ == join(['  foo = "bar"',
                      \'',
                      \'  if foo == "bar" do',
                      \'    "baz"',
                      \'  end'], "\n")
  end
end
