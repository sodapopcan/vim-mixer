" mixer.vim - Extra goodies for working with Elixir
" Maintainer:   Andrew Haust <https://andrew.hau.st>
" Version:      0.1

if exists('g:loaded_mixer') || &cp
  finish
endif
let g:loaded_mixer = 1

let g:async_runners = [
      \   'Dispatch',
      \   'Neomake',
      \   'AsyncRunner',
      \   'AsyncDo'
      \ ]

augroup mixer
  autocmd!
  autocmd BufNewFile,BufReadPost * call s:setup_buff()
  autocmd FileType elixir,eelixir call mixer#define_mappings()
augroup END

" Options {{{1

let g:mixer_enable_textobj_arg = get(g:, 'mixer_enable_textobj_arg', 1)
let g:mixer_async_command = get(g:, 'mixer_async_command', 0)

" SetupBuff {{{1

function MixerDetect()
  let mix_file = findfile("mix.exs", ".;", 2)
  let nested = 1
  let project_root = ''

  if empty(mix_file)
    let mix_file = findfile("mix.exs", ".;")
    let nested = 0
  endif

  if !empty(mix_file)
    let project_root = fnamemodify(mix_file, ':p:h')

    if project_root ==# ""
      let project_root = "."
    endif

    return [project_root, mix_file, nested]
  else
    return ['', '', 0]
  endif
endfunction

function! s:command_exists(cmd)
  return exists(":".a:cmd) == 2
endfunction

function! s:setup_buff() abort
  if !s:command_exists("Mix")
    command -buffer -bang -complete=customlist,mixer#MixerMixComplete -nargs=* Mix call mixer#Mix(<bang>0, <f-args>)
  endif

  let [project_root, _mix_file, _nested] = MixerDetect()

  if !empty(project_root) && !exists('g:mix_projects') || (exists('g:mix_projects') && !has_key(g:mix_projects, project_root))
    call mixer#setup_mix_project()
  endif

  if exists('g:mix_projects') && has_key(g:mix_projects, project_root)
    let b:mix_project = g:mix_projects[project_root]
  endif

  augroup mixerAutoload
    autocmd!
    autocmd DirChanged * call mixer#setup_mix_project()
  augroup END

  if exists('b:mix_project')
    if !s:command_exists("Deps")
      command -buffer -complete=customlist,mixer#MixerDepsComplete -range -bang -nargs=* Deps call mixer#Deps(<bang>0, <q-mods>, <range>, <line1>, <line2>, <f-args>)
    endif
  endif

  if exists('b:mix_project') && b:mix_project.has_phoenix
    if !s:command_exists("R")
      command -buffer -nargs=0 R call mixer#R('edit')
    endif

    if !s:command_exists("RE")
      command -buffer -nargs=0 RE call mixer#R('edit')
    endif

    if !s:command_exists("RS")
      command -buffer -nargs=0 RS call mixer#R('split')
    endif

    if !s:command_exists("RV")
      command -buffer -nargs=0 RV call mixer#R('vsplit')
    endif

    if !s:command_exists("RT")
      command -buffer -nargs=0 RT call mixer#R('tabedit')
    endif
  endif

  if exists('b:mix_project') && b:mix_project.has_ecto
    if !s:command_exists("Gen")
      command -buffer -complete=customlist,mixer#MixerGenComplete -bang -nargs=* Gen call mixer#Gen(<bang>0, <f-args>)
    endif

    if !s:command_exists("Migrate")
      command -buffer -complete=customlist,mixer#MixerMigrationComplete -count=1 -bang -nargs=* Migrate call mixer#Migrate(<bang>0, <count>, <f-args>)
    endif
  endif
endfunction
