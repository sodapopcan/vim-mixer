" Check if cursor in range of two positions.
" Positions are in the form of [line, col].
function! elixir_ext#util#in_range(start, end) abort
  let [start_lnr, start_col] = a:start
  let [end_lnr, end_col] = a:end
  let lnr = line('.')
  let col = col('.')

  if lnr > start_lnr && lnr < end_lnr | return 1 | endif

  if lnr == start_lnr && lnr == end_lnr
    return col >= start_col && col <= end_col
  endif

  if lnr == start_lnr && col >= start_col | return 1 | endif
  if lnr == end_lnr && col <= end_col | return 1 | endif

  return 0
endfunction

function! elixir_ext#util#empty_parens()
  let save_i = @i
  normal! "iyib
  let is_empty = empty(trim(@i))
  let @i = save_i

  return is_empty
endfunction

function! elixir_ext#util#cursor_term()
  return synIDattr(synID(line('.'), col('.'), 1), "name")
endfunction

function! elixir_ext#util#outer_term()
  let terms = map(synstack(line('.'), col('.')), 'synIDattr(v:val,"name")')

  let terms = filter(terms, 'v:val !=# "elixirBlock"')

  if empty(terms) | return '' | endif

  return substitute(substitute(terms[0], 'elixir', '', ''), 'Delimiter', '', '')
endfunction
