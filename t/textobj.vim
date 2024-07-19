source t/_helpers.vim

silent filetype plugin indent on
syntax enable

set cpo&vim

describe "text objects"
  it "with__single_line_body"
    call TestTextObject('textobj/with__single_line_body.ex')
  end
end
