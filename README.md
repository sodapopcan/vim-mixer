# mixer.vim

Plugin for working with Mix projects and Elixir files.

Text objects require [elixir.vim](https://github.com/elixir-editors/vim-elixir).

## Features

- Text objects
  - `ad`/`id` - Any macro with a `do` block.  Works on user-defined macros as
    well as keyword syntax.
  - `af`/`if` - A function/macro definition
  - `aF` - A function/macro definition including all heads, docs, and annotations (`iF` exists for convenience but is identical to `if`).
  - `iS`/`aS`- A sigil
  - `im`/`am`- A map or struct
  - `iM`/`aM`- A module
  - `ic`/`ac`- A comment

- Conveniences
  - `'commentstring'` is dynamically set in embedded HEEx/Surface.
  - [matchit](https://www.vim.org/scripts/script.php?script_id=39) works in
    embedded HEEx/Surface templates.
  - Automatically sets `:compiler` if the appropriate plugin is found.

- Commands
  - `:Mix`: Run a mix command with autocomplete.  Uses
    [dispatch](https://github.com/tpope/vim-dispatch) or
    [asyncrun](https://github.com/skywind3000/asyncrun.vim)if available.
  - `:Deps` for added `:Mix deps` functionality, like dynamically adding
    packages or just jumping to your `deps` function (no matter what you've call it).
  - `:Gen` is a unified command for running `gen` tasks (with autocomplete!), eg:
    - `:Gen migration add_name_to_users`
    - `:Gen live Accounts User users name:string age:integer`

See `:help mixer` for more!

## Recommended Plugins

- [elixir.vim](https://github.com/elixir-editors/vim-elixir)

  Not strictly required for nvimmers.

- [closetag](https://github.com/alvan/vim-closetag)

  Auto-close HTML tags.  Mixer is aware of this plugin and will extend
  `g:closetag_regions` for you do it will work with your cursor inside
  `~H` or `~F`.  Due to the way closetag is implemented, you must
  configure the appropriate filetypes on your own.

- [splitjoin.vim](https://github.com/AndrewRadev/splitjoin.vim)

  Among other things, it lets you pipe and unpipe args, though unnecessary if
  you use snippets or the like.

- [endwise.vim](https://github.com/tpope/vim-endwise)

  Auto-adds `end` after hitting `<cr>` in insert mode (or just use copilot,
  I guess).

## In the works

- Projections
- Migration commands
- Text Object improvements

## License

Distributed under the same terms as Vim itself. See `:help license`.
