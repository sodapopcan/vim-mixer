# mixer.vim

Plugin for working with Mix projects and Elixir files.

Some functionality, like text objects, depend on [elixir.vim](https://github.com/elixir-editors/vim-elixir).

## Features

### Text objects
- `ad`/`id` - Any macro with a `do` block.  Works on user-defined macros as
  well as keyword syntax.
- `aD` - Like `ad` but include any assignment and/or attached comments (`iD`
  exists for convenience but is identical to `id`).
- `af`/`if` - A function/macro definition
- `aF` - Like `af` but include all heads, docs, annotations, `attr` and
  `slot` declarations, and even matching `do_`-prefixed heads (`iF` exists
  for convenience but is identical to `if`).
- `iS`/`aS`- A sigil
- `im`/`am`- A map or struct
- `iM`/`aM`- A module
- `ic`/`ac`- A comment or documentation

### Conveniences
- `'commentstring'` is dynamically set in embedded HEEx/Surface.
- [matchit](https://www.vim.org/scripts/script.php?script_id=39) works in
  embedded HEEx/Surface templates.
- Automatically sets `:compiler` if the appropriate plugin is found.
- [experimental] Remaps `ctrl-]` in templates that will jump to a phx-hook
  definition (it's pretty smart about it) or event handlers on other `phx-`
  attributes.  Unfortunately this has a dependency on git-grep atm.

### Commands
- `:Mix` runs a mix command with autocomplete.
  - Uses [dispatch](https://github.com/tpope/vim-dispatch), [neomake](https://github.com/neomake/neomake),
  [asyncrun](https://github.com/skywind3000/asyncrun.vim), or [asyncdo](https://github.com/hauleth/asyncdo.vim)
  if available.
  - `:Mix!` does whatever the `!` version of your async runner does
  - `:Mix ! cmd` to run via `:!`--incidentally, `:Mix!!` also works.
- `:Deps` doesn't just wrap `Mix deps` but adds functionality like dynamically adding
  packages under your cursor (`:Deps add floki`, for example) or jumping to your `deps`
  function no matter what you've called it (`:Deps` with no args).
- `:Gen` is a unified command for running `gen` tasks (with autocomplete!), eg:
  - `:Gen migration add_name_to_users`
  - `:Gen live Accounts User users name:string age:integer`
- `:IEx` starts a `:term` window running iex.
  - Within a mix project `-S mix` is the default; use `:IEx!` to get a plain session.
  - Give a range or in visual mode, load the selected lines into a new `:term`
    session.  This "connects" the two, updating the terminal with any changes
    to the selected region.

See `:help mixer` for more details!

## Recommended Plugins

- [closetag](https://github.com/alvan/vim-closetag)

  Auto-close HTML tags.  Mixer is aware of this plugin and will extend
  `g:closetag_regions` for you so it will work with your cursor inside
  `~H` or `~F`.  Due to the way closetag is implemented, you must
  configure the appropriate filetypes on your own.

- [splitjoin.vim](https://github.com/AndrewRadev/splitjoin.vim)

  Among other things, it lets you pipe and unpipe args.

- [endwise.vim](https://github.com/tpope/vim-endwise)

  Auto-adds `end` after hitting `<cr>` in insert mode (or just use copilot,
  I guess).

## License

Distributed under the same terms as Vim itself. See `:help license`.
