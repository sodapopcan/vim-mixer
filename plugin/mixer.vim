" mixer.vim - Extra goodies for working with Elixir
" Maintainer:   Andrew Haust <https://andrew.hau.st>
" Version:      0.1

if exists('g:loaded_mixer') || &cp
  finish
endif
let g:loaded_mixer = 1

augroup mixerHTML
  autocmd!
  autocmd FileType elixir,eelixir call mixer#define_mappings()
  autocmd BufEnter * call mixer#init()
  autocmd CursorMoved *.ex call s:set_close_tag_file_type()
augroup END

function! s:cursor_syn_groups() abort
  return join(map(synstack(line('.'), col('.')), 'synIDattr(v:val,"name")'), ",")
endfunction

function! s:set_close_tag_file_type()
  if !exists('g:loaded_closetag') | return | endif

  if exists('b:did_ftplugin_closetag')
    unlet b:did_ftplugin_closetag
  endif

  let groups = s:cursor_syn_groups()

  if groups =~ 'HeexSigil\|SurfaceSigil'
    if g:closetag_filenames !~ ',\*\.ex$'
      let g:closetag_filenames = g:closetag_filenames.",*.ex"
    endif
  else
    let g:closetag_filenames = substitute(g:closetag_filenames, ',\*\.ex$', '', '')
  endif
endfunction
