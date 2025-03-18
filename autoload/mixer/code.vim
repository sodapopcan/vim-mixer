vim9script

import autoload './cursor.vim'

const RENDER_REGEX = '^\s*def render\%((assigns.*)\|(.*=\s\+assigns)\)'
const Skip = () => cursor.OnStringOrComment()

export def HasRenderCallback(): bool
  return search(RENDER_REGEX, 'n', 0, 0, Skip) > 0
enddef

export def IsController(): bool
  return expand('%:t:r') =~ '_controller$'
enddef

export def IsHtml(): bool
  return expand('%:t:r') =~ '_html$'
enddef

export def IsView(): bool
  return expand('%:t:r') =~ '_view$'
enddef

export def IsTemplateFile(): bool
  return expand('%:e') == 'heex'
enddef
