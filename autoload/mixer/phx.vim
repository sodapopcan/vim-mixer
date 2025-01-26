vim9script

import autoload './cursor.vim'
import autoload './util.vim'
import autoload './textprop.vim'

# RCommand {{{1

const RENDER_REGEX = '^\s*def render\%((assigns.*)\|(.*=\s\+assigns)\)'
const DEFS = ['mount', 'handle_', 'update']
const Skip = () => cursor.OnStringOrComment()

export def HasRender(): bool
  return search(RENDER_REGEX, 'n', 0, 0, Skip) > 0
enddef

const R = {
  alt_pos: [0, 0],
  render_pos: [0, 0],
  render_index: 0
}

export def MarkRenderFunctions()
  textprop.Ensure('render')

  const view = winsaveview()

  try
    cursor.Set([1, 1])

    while search(RENDER_REGEX, 'W') > 0
      var [end_lnr, _] = searchpairpos('\<def\>\|\<fn\>', '', '\<end\>', 'Wn', Skip)
      textprop.Multi('render', bufnr(), line('.'), end_lnr)
    endwhile
  finally
    winrestview(view)
  endtry
enddef

export def DefineRCommand()
  command! -buffer -nargs=0 R RCommand()
enddef

export def RCommand()
  if HasRender()
    HandleEmbeddedTemplate()
  else
    HandleExternalTemplate()
  endif
enddef

def HandleEmbeddedTemplate()
  if !exists('b:mixer_r')
    var view = winsaveview()
    b:mixer_r = deepcopy(R)

    if cursor.InRender()
      b:mixer_r.alt_pos = [1, 1]
    else
      b:mixer_r.alt_pos = cursor.Pos()
    endif

    augroup mixerRCommand
      autocmd!
      autocmd CursorHold,InsertLeave *.ex,*.exs,*.heex,*.sface,*.leex if cursor.InRender()
        |   b:mixer_r.alt_pos = cursor.Pos()
        | else
        |   b:mixer_r.alt_pos = cursor.Pos()
        | endif
    augroup END

    winrestview(view)
  endif

  if cursor.InRender()
    cursor.Set(b:mixer_r.alt_pos)
  else
    cursor.Set(b:mixer_r.render_pos)
  endif
enddef

def HandleExternalTemplate()
  var file: string
  var action: string
  var jump: number

  if &ft ==# 'elixir'
    # First just see if there is a collocated heex file with the same name
    const collocated = util.Sub(expand("%:p"), '\.ex$', '.html.heex')

    if util.FileExists(collocated)
      exec "edit" collocated

      return
    endif

    const template_regex = '\%(render(conn, \||> render(\)[:"]\zs\k\+\%(\.\k\+\)\='
    var func = cursor.CurrentFunction()

    if func.name != ''
      var render_lnr = search('render(', 'Wnc', func.end_pos[0], 0, Skip)

      if render_lnr == 0
        render_lnr = search('render(', 'Wncb', func.def_pos[0], 0, Skip)
      endif

      var view = render_lnr->getline()->matchstr(template_regex)

      if empty(view)
        view = func.name
      endif

      if match(view, '\.html$') < 0
        view ..= ".html"
      endif

      file = findfile(view, util.RelativeDir() .. "/**/*")
    else
      file = expand('%')->util.Sub('_controller', '_html')
    endif
  else
    # Look for collocated first, this should take care of LiveViews
    const collocated = util.Sub(expand("%:p"), '\.html.heex$', '.ex')

    if util.FileExists(collocated)
      exec "edit" collocated

      return
    endif

    action = expand('%:t')->split('\.')[0]
    file = expand('%:h')->util.Sub('_html', '_controller.ex')
  endif

  if file != ""
    exec "edit" file

    if !cursor.InFunction(action)
      search("def " .. action)
    endif
  else
    echom "Can't find file"
  endif
enddef

# Jump to event handler/hook {{{1

export def DefineFindEvent()
  if !empty(system('command -v git'))
    nnoremap <silent> <buffer> <c-]> :call <sid>FindEvent()<cr>
  endif
enddef

def FindEvent()
  const cursor_word = expand('<cWORD>')
  const prefix = b:mix_project.bindingPrefix

  if cursor_word !~ prefix
    exec "normal! \<c-]>"

    return
  endif

  var char: string

  if util.Matches(cursor_word, prefix .. '.\+=''')
    char = ''''
  elseif util.Matches(cursor_word, prefix .. '.\+="')
    char = '"'
  else
    exec "normal! \<c-]>"

    return
  endif

  var cursor_pos = cursor.Pos()

  # Probably a better way to do this.
  var save_i = @i
  exec 'normal! "iyi' .. char
  const token = @i
  @i = save_i

  if cursor_word =~ '^' .. prefix .. 'hook'
    call HandlePhxHook(token, cursor_pos)
  else
    call HandlePhxEvent(token, cursor_pos)
  endif
enddef

def HandlePhxHook(token: string, cursor_pos: list<number>)
  var results = systemlist("git grep -n '" .. token .. " = ' -- :/'*.js' :/'*.ts'")

  if len(results) > 0
    const result = split(results[0], ':')
    var file = result[0]
    var lnr = result[1]
    normal! m'
    exec "silent keepjumps edit" file
    exec "keepjumps :" .. lnr
  else
    var files = FindJsFile(token)

    if !empty(files)
      normal! m'

      exec "silent keepjumps edit" files[0]
    else
      call cursor.Set(cursor_pos)
      util.Error("Can't find definition")

      return
    endif
  endif
enddef

def FindJsFile(token_arg: string): list<string>
  final tracked = systemlist("git ls-files -- '*.js' ':!:priv/'")
  final untracked = systemlist("git ls-files --others -- '*.js' ':!:deps/' ':!:priv/'")
  const files = extend(tracked, untracked)
  var token = util.Gsub(token_arg, '-\|_', '')

  return matchfuzzy(files, token)
enddef

def HandlePhxEvent(token: string, cursor_pos: list<number>)
  var template = ''
  var flags = 's'

  if expand('%:e') =~ 'heex\|sface'
    template = expand('%')
    flags = ''
    const exfile = util.Sub(template, '\.html\.\<heex\|sface\>$', '\.ex')

    if util.FileExists(exfile)
      normal! m'

      exec "silent keepjumps edit" exfile
    else
      util.Error("Cannot find Elixir file")

      return
    endif
  endif

  if !search('def handle_event(\%(\s\|\n\)*"\<' .. token .. '\>', flags)
    util.Error("Cannot find definition")

    if !empty(template)
      exec "silent keepjumps edit" template
    endif

    call cursor.Set(cursor_pos)
  endif
enddef
