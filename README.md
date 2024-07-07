# elixir-ext.vim

Extra goodies for developing Elixir applications and Mix projects.

Some functionality depends on [elixir.vim](https://github.com/elixir-editors/vim-elixir/) and [projectionist.vim](https://github.com/tpope/vim-projectionist).

NeoVim users: YMMV.  I recommend [elixir-tools.nvim](https://github.com/elixir-tools/elixir-tools.nvim) instead.

## Features

- `:Mix` for runnings mix commands with completions (will use [dispatch.vim](https://github.com/tpope/vim-dispatch) if available).
- `:Generate` for unifying generator commands, ex:
  ```viml
  :Generate migration add_name_to_users
  :Generate live Accounts User users name:string age:integer
  ```
  Uses [dispatch.vim](https://github.com/tpope/vim-dispatch) if available.
- `:R` for jumping between controllers and templates
  - With your cursor within the `index` controller action, `:R` will take you to
    either `index.html.heex` or to the relevant `HTML` module with your cursor
    placed on the `index` component.
  - In a LiveView that uses separate heex templates, it will jump between the
    two files.
  - In a LiveView with a render function, it will jump between `render` and
    whever your cursor was last at.  If called for the first time from a render
    function, it will take to you the first available callback.
- [projectionist.vim](https://github.com/tpope/vim-projectionist) support\
  I generally believe projectionist commands are very personal, so elixir-ext
  aims to provide something a little more special than a typical configuration.
  Elixir-ext will figure out a bunch of things about your
  project to define projections.  In a standard Phoenix directory structure,
  you will get the following commands:
  - `:Edomain`: Edit files in `lib/my_app`, eg: `:Edomain accounts/users`
  - `:Eweb`: Edit files in `lib/my_app_web`, eg: `:Eweb router`
  - `:Eapplication`: Edit the application file.
    - Looks in the following places:
      - `lib/my_app/app[lication].ex`
      - `lib/my_app/app.ex`
      - `lib/my_app_app[lication].ex`
      - `lib/my_app_app.ex`
  - `:Erouter`: Edit the router
  - `:Eendpoint`: Edit the endpoint
  - `:Emix`: Edit `mix.exs`
  - `:Egettext`: Edit `gettext.ex`
  - `:Ejavascript`: Edit files in `assets/js`
  - `:Estyle`: Edit files in `assets/css`
  - `:Evendor`: Edit files in `assets/vendor`
  - `:Etailwind`: Edit `assets/tailwind.config.js`
- `:ToPipe` and `:FromPipe` for piping and unpiping arguments.
