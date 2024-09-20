vim9script

import autoload './cursor.vim'
import autoload './util.vim'

const RENDER = '^\s*\zsdef render\%((assigns.*)\|(.*=\s\+assigns)\)'
const DEFS = ['mount', 'handle_', 'update']
const Skip = () => cursor.OnStringOrComment()

# RCommand {{{1

export def HasRender(): bool
  return search(RENDER, 'n', 0, 0, () => cursor.OnStringOrComment()) > 0
enddef

# TODO: Handle keyword syntax
def InRender(): bool
  const cursor_origin = cursor.Pos()
  const view = winsaveview()
  var def_pos = [0, 0]
  var end_pos = [0, 0]

  def_pos = searchpos(RENDER, 'Wbc', 0, 0, Skip)

  if def_pos != [0, 0]
    end_pos = searchpairpos('\<def\>\|\<fn\>', '', '\<end\>', 'W', Skip)
  else
    return false
  endif

  winrestview(view)

  return util.InRange(cursor_origin, def_pos, end_pos)
enddef

const R = {
  alt_pos: [0, 0],
  render_pos: [[0, 0]],
  render_index: 0
}

export def RCommand(type: string): void
  if HasRender()
    b:mixer_impl = get(b:, 'mixer_impl', {
      def_pos: [0, 0],
      cursor_pos: [0, 0],
    })

    b:mixer_render = get(b: 'mixer_render', {
      def_pos
    })

    if InRender()
      b:mixer_rel.imp_pos = cursor.Pos()

      if b:imixer_rel.mpl_pos != [0, 0]
        exec ':' .. b:impl_lnr
      else
        for def in DEFS
          if search('^\s*def\s\+' .. def .. '(') > 0
            break
          endif
        endfor
      endif
    else
      b:impl_lnr = line('.')

      if b:tpl_lnr
        exec ':' .. b:tpl_lnr
      else
        search('^\s\+def render(')
      endif
    endif
  else
    var basename: string
    if &ft ==# 'elixir'
      basename = util.Sub(expand("%:p"), '\.ex$', '.html.heex')
    else
      basename = util.Sub(expand("%:p"), '\.html.heex$', '.ex')
    endif

    if util.FileExists(basename)
      exec type basename
    endif
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
