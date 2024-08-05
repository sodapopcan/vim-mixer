# mixer.vim

Extra goodies for developing Elixir applications and Mix projects.

Some functionality depends on [projectionist.vim](https://github.com/tpope/vim-projectionist).

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
  - [matchit](https://www.vim.org/scripts/script.php?script_id=39) works in
    HEEx/Surface templates.
  - Automatically sets `:compiler` if the appropriate plugin is found.  (for Vim
    users, this requires elixir.vim)

- Commands
  - `:Mix` for runnings mix commands with autocomplete.  Uses [dispatch](https://github.com/tpope/vim-dispatch)
    if available.  PRs for other popular async runners are welcome.
  - `:Deps` for added `:Mix deps` functionality, like dynamically adding
    packages or just jumping to your `deps` function (no matter what you've call it).
  - `:Gen` is a unified command for running `gen` tasks, eg:
    - `:Gen migration add_name_to_users`
    - `:Gen live Accounts User users name:string age:integer`
  - `:R` for jumping between controllers and templates
    - If the module has a `render/1` function, it will jump to those and back to
      where you were before.

- [Projectionist](https://github.com/tpope) support with dynamic definitions
  based on your project's name.

See `:help mixer` for full details.

## Recommended Plugins

- [elixir.vim](https://github.com/elixir-editors/vim-elixir)
  - Not strictly required for nvimmers.
- [closetag](https://github.com/alvan/vim-closetag)
  - Auto-close HTML tags.  Mixer is aware of this plugin and will auto-activate
    it when your cursor is inside `~H` or `~F`.
- [splitjoin.vim](https://github.com/AndrewRadev/splitjoin.vim)
  - Among other things, it lets you pipe and unpipe args.
- [endwise.vim](https://github.com/tpope/vim-endwise)
  - Auto-adds `end` after hitting `<cr>` in insert mode.

-------------------
  - With your cursor within the `index` controller action, `:R` will take you to
    either `index.html.heex` or to the relevant `HTML` module with your cursor
    placed on the `index` component.
  - In a LiveView that uses separate heex templates, it will jump between the
    two files.
  - In a LiveView with a render function, it will jump between `render` and
    wherever your cursor was last at.  If called for the first time from a render
    function, it will take to you the first available callback.
- [projectionist.vim](https://github.com/tpope/vim-projectionist) support\
  I generally believe projectionist commands are very personal, so mixer
  aims to provide something a little more special than a typical configuration.
  Elixir-ext will figure out a bunch of things about your
  project to define projections.  In a standard Phoenix directory structure,
  you will get the following commands:
  - `:Edomain`: Edit files in `lib/my_app`, eg: `:Edomain accounts/users`
  - `:Eweb`: Edit files in `lib/my_app_web`, eg: `:Eweb router`
  - `:Eapplication`: Edit the application file.
    - Looks in the following places:
      - `lib/my_app/application.ex`
      - `lib/my_app/app.ex`
      - `lib/my_app_application.ex`
      - `lib/my_app_app.ex`
  - `:Ejavascript`: Edit files in `assets/js`
  - `:Estyle`: Edit files in `assets/css`
  - `:Erouter`: Edit the router
  - `:Eendpoint`: Edit the endpoint
  - `:Emix`: Edit `mix.exs`
  - `:Egettext`: Edit `gettext.ex`
  - `:Evendor`: Edit files in `assets/vendor`
  - `:Etailwind`: Edit `assets/tailwind.config.js`

## TODO
- [ ] Fix "ci" going into insert mode when no textobj is found
- [ ] Detect umbrella projects
- [ ] Detect nested projects

## License

Distributed under the same terms as Vim itself. See `:help license`.
