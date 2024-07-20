source t/_helpers.vim

silent filetype plugin indent on
syntax enable

set cpo&vim

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
      TestTextObject textobj/def/multiple.ex
    end
  end
end
