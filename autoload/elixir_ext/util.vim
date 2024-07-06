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

function! elixir_ext#util#empty_delimiters(start, end)
  let [start_lnr, start_col] = a:start
  let [end_lnr, end_col] = a:end

  if start_lnr == end_lnr && end_col == start_col + 1
    return 1
  else
    return 0
  endif
endfunction
