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
      let f = Fixture('fixtures/textobj_ad__single_line_block_no_module.ex')
      Cursor 1 1

      normal dad

      Expect Buffer() == f.buffer
      Expect @" == f.reg."\n"
    end

    it 'deletes a block with the cursor in the body'
      let f = Fixture('fixtures/textobj_ad__single_line_block_no_module.ex')
      Cursor 2 3

      normal dad

      Expect Buffer() == f.buffer
      Expect @" == f.reg."\n"
    end

    it 'deletes a block with the cursor on `end`'
      let f = Fixture('fixtures/textobj_ad__single_line_block_no_module.ex')
      Cursor 3 3

      normal dad

      Expect Buffer() == f.buffer
      Expect @" == f.reg."\n"
    end
  end

  context "multiline function heads"
    it 'deletes when block'
      let f = Fixture('fixtures/textobj_ad__multiline_function_head.ex')
      Cursor 5 3

      normal dad

      Expect Buffer() == f.buffer
      Expect @" == f.reg."\n"
    end

    it 'deletes a single multi-line map argument'
      let f = Fixture('fixtures/textobj_ad__multiline_single_map_arg.ex')
      Cursor 3 3

      normal dad

      Expect Buffer() == f.buffer
      Expect @" == f.reg."\n"
    end
  end

  context "with"
    it 'deletes a single-clause with'
      let f = Fixture('fixtures/textobj_ad__with_single_line.ex')
      Cursor 3 5

      normal dad

      Expect Buffer() == f.buffer
      Expect @" == f.reg."\n"
    end
  end
end
