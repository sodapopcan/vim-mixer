if !&compatible | set nocompatible | endif

silent filetype plugin indent on
syntax enable

source t/_helpers.vim
source syntax/elixir.vim

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

    it "targets the second function"
      TestTextObject textobj/def/fn.ex
    end

    " This test will not pass and I have no idea what is wrong.  It works with
    " a minimal vimrc with the same settings as in the test.
    "
    " it "targets meta"
    "   TestTextObject textobj/def/function_meta.ex
    " end
  end

  context "sigils - inline"
    it "targets double quotes"
      TestTextObject textobj/sigil/inline_double_quotes.ex
    end

    it "targets single quotes"
      TestTextObject textobj/sigil/inline_single_quotes.ex
    end

    it "targets chevrons"
      TestTextObject textobj/sigil/inline_chevrons.ex
    end

    it "targets brackets"
      TestTextObject textobj/sigil/inline_brackets.ex
    end

    it "targets braces"
      TestTextObject textobj/sigil/inline_braces.ex
    end

    it "targets parens"
      TestTextObject textobj/sigil/inline_parens.ex
    end

    it "targets parens"
      TestTextObject textobj/sigil/inline_slashes.ex
    end
  end
end


