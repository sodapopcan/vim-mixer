# Contributing

## General guidelines

Contributions are very welcome!  My only ask in terms of the codebase is to try
and match the style that is already there.  Noteably:

  - Variables and functions are `camcel_case`.
  - Functions defining commands are `Uppercase`.
  - Don't use `l:` unless necessary (like `l:count`, though you probably
    shouldn't call a variable `count` anyway).
  - All functions should be script local unless there is a resaon to make them
    public.
  - Public functions must be documented.
  - Do not introduce new files unless absolutely necessary.  This one may be
    more controversial but I prefer to work in one file per directory.
  - There is no line limit but keep lines on the shorter side.

As for writing documentation:

  - Use American spelling except for the word "behaviour."
  - A period is followed by two spaces.
  - Use Oxford comma.

If for some reason you refuse to do anything of these things I won't block the
PR, but I will fix them on my own in a subsequent commit.

## Adding an async runner

If you're making a pull request to add an async runner, look for a variable
called `s:async_runners`.  Add the command to the list without the preceeding `:`.
