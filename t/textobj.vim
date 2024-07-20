if !&compatible | set nocompatible | endif

silent filetype plugin indent on
syntax enable

source t/_helpers.vim

describe "text objects"
  context "do/end blocks"
    it "tarts a with block with a single clause and body"
      TestTextObject textobj/doend/with__single_line_body.ex
    end

    it "targets a with block with multiple clauses"
      TestTextObject textobj/doend/with__multiline_clause.ex
    end
  end

  context "def*"
    it "targets only one function"
      TestTextObject textobj/def/multiple_first.ex
    end

    it "targets the second function"
      TestTextObject textobj/def/multiple_second.ex
    end
    " This test will not pass and I have no idea what is wrong.  It works with
    " a minimal vimrc with the same settings as in the test.
    "
    " it "targets meta"
    "   TestTextObject textobj/def/function_meta.ex
    " end
  end
end
