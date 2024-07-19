runtime! plugin/elixir-mix.vim
source t/_helpers.vim

silent filetype plugin indent on
syntax enable

describe "function call with do block"
  before
    new
    set ft=elixir
  end

  after
    close!
  end

  it "string_is_func_name"
    let code = ['hello "hello" do',
               \'  true',
               \'end']
    call append(0, code)
    1
    $

    call elixir_mix#test_search_call_from_do('hello')
    Expect [line('.'), col('.')] == [1, 1]
  end

  it "multi_line_with_single_map"
    let code =
          \['some_var %{',
          \ '  hi: "hi",',
          \ '  some_var: "some_var"',
          \ '} do',
          \ '  true',
          \ 'end']
    call append(0, code)
    4
    3

    call elixir_mix#test_search_call_from_do('some_var')
    Expect [line('.'), col('.')] == [1, 1]
  end
end
