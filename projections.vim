  # final projectionist_heuristics = {
  #   "lib/**/views/*_view.ex": {
  #     "type": "view",
  #     "alternate": "test/{dirname}/views/{basename}_view_test.exs",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View do",
  #       "  use {dirname|camelcase|capitalize}, :view",
  #       "end"
  #     ]
  #   },
  #   "test/**/views/*_view_test.exs": {
  #     "type": "test",
  #     "alternate": "lib/{dirname}/views/{basename}_view.ex",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ViewTest do",
  #       "  use ExUnit.Case, async: true",
  #       "",
  #       "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View",
  #       "end"
  #     ]
  #   },
  #   "lib/**/controllers/*_controller.ex": {
  #     "type": "controller",
  #     "alternate": "test/{dirname}/controllers/{basename}_controller_test.exs",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Controller do",
  #       "  use {dirname|camelcase|capitalize}, :controller",
  #       "end"
  #     ]
  #   },
  #   "test/**/controllers/*_controller_test.exs": {
  #     "type": "test",
  #     "alternate": "lib/{dirname}/controllers/{basename}_controller.ex",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ControllerTest do",
  #       "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
  #       "end"
  #     ]
  #   },
  #   "lib/**/controllers/*_html.ex": {
  #     "type": "html",
  #     "alternate": "test/{dirname}/controllers/{basename}_html_test.exs",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}HTML do",
  #       "  use {dirname|camelcase|capitalize}, :html",
  #       "",
  #       "  embed_templates \"{basename|snakecase}_html/*\"",
  #       "end"
  #     ]
  #   },
  #   "test/**/controllers/*_html_test.exs": {
  #     "type": "test",
  #     "alternate": "lib/{dirname}/controllers/{basename}_html.ex",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}HTMLTest do",
  #       "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
  #       "",
  #       "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}HTML",
  #       "end"
  #     ]
  #   },
  #   "lib/**/controllers/*_json.ex": {
  #     "type": "json",
  #     "alternate": "test/{dirname}/controllers/{basename}_json_test.exs",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}JSON do",
  #       "end"
  #     ]
  #   },
  #   "test/**/controllers/*_json_test.exs": {
  #     "type": "test",
  #     "alternate": "lib/{dirname}/controllers/{basename}_json.ex",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}JSONTest do",
  #       "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
  #       "",
  #       "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}JSON",
  #       "end"
  #     ]
  #   },
  #   "lib/**/components/*.ex": {
  #     "type": "component",
  #     "alternate": "test/{dirname}/components/{basename}_test.exs",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize} do",
  #       "  use Phoenix.Component",
  #       "end"
  #     ]
  #   },
  #   "test/**/components/*_test.exs": {
  #     "type": "test",
  #     "alternate": "lib/{dirname}/components/{basename}.ex",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Test do",
  #       "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
  #       "",
  #       "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}",
  #       "end"
  #     ]
  #   },
  #   "lib/**/live/*_component.ex": {
  #     "type": "livecomponent",
  #     "alternate": "test/{dirname}/live/{basename}_component_test.exs",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Component do",
  #       "  use {dirname|camelcase|capitalize}, :live_component",
  #       "end"
  #     ]
  #   },
  #   "test/**/live/*_component_test.exs": {
  #     "type": "test",
  #     "alternate": "lib/{dirname}/live/{basename}_component.ex",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ComponentTest do",
  #       "  use {dirname|camelcase|capitalize}.ConnCase",
  #       "",
  #       "  import Phoenix.LiveViewTest",
  #       "end"
  #     ]
  #   },
  #   "lib/**/live/*.ex": {
  #     "type": "liveview",
  #     "alternate": "test/{dirname}/live/{basename}_test.exs",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize} do",
  #       "  use {dirname|camelcase|capitalize}, :live_view",
  #       "end"
  #     ]
  #   },
  #   "test/**/live/*_test.exs": {
  #     "type": "test",
  #     "alternate": "lib/{dirname}/live/{basename}.ex",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Test do",
  #       "  use {dirname|camelcase|capitalize}.ConnCase",
  #       "",
  #       "  import Phoenix.LiveViewTest",
  #       "end"
  #     ]
  #   },
  #   "lib/**/channels/*_channel.ex": {
  #     "type": "channel",
  #     "alternate": "test/{dirname}/channels/{basename}_channel_test.exs",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel do",
  #       "  use {dirname|camelcase|capitalize}, :channel",
  #       "end"
  #     ]
  #   },
  #   "test/**/channels/*_channel_test.exs": {
  #     "type": "test",
  #     "alternate": "lib/{dirname}/channels/{basename}_channel.ex",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ChannelTest do",
  #       "  use {dirname|camelcase|capitalize}.ChannelCase, async: true",
  #       "",
  #       "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel",
  #       "end"
  #     ]
  #   },
  #   "test/**/features/*_test.exs": {
  #     "type": "feature",
  #     "template": [
  #       "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Test do",
  #       "  use {dirname|camelcase|capitalize}.FeatureCase, async: true",
  #       "end"
  #     ]
  #   },
  #   "lib/*.ex": {
  #     "type": "domain",
  #     "alternate": "test/{}_test.exs",
  #     "template": ["defmodule {camelcase|capitalize|dot} do", "end"],
  #   },
  #   "test/*_test.exs": {
  #     "type": "test",
  #     "alternate": "lib/{}.ex",
  #     "template": [
  #       "defmodule {camelcase|capitalize|dot|elixir_module}Test do",
  #       "  use ExUnit.Case, async: true",
  #       "",
  #       "  alias {camelcase|capitalize|dot|elixir_module}",
  #       "end"
  #     ]
  #   },
  #   "lib/mix/tasks/*.ex": {
  #     "type": "task",
  #     "alternate": "test/mix/tasks/{}_test.exs",
  #     "template": [
  #       "defmodule Mix.Tasks.{camelcase|capitalize|dot} do",
  #       "  @shortdoc \"{}\"",
  #       "",
  #       "  @moduledoc \"\"\"",
  #       "  {}",
  #       "  \"\"\"",
  #       "",
  #       "  use Mix.Task",
  #       "",
  #       "  @impl true",
  #       "  @doc false",
  #       "  def run(argv) do",
  #       "",
  #       "  end",
  #       "end"
  #     ]
  #   },
  #   'mix.exs': {
  #     'type': 'mix',
  #     'alternate': 'mix.lock',
  #     'dispatch': 'mix deps.get'
  #   },
  #   'mix.lock': {
  #     'type': 'lock',
  #     'alternate': 'mix.exs',
  #     'dispatch': 'mix do deps.unlock --all, deps.update --all'
  #   },
  #   'config/*.exs': {
  #     'type': 'config',
  #     'related': 'config/config.exs'
  #   },
  #   'priv/repo/migrations/*.exs': {
  #     'type': 'migration', 'dispatch': 'mix ecto.migrate'
  #   }
  # }

  if !empty(b:mix_project.name)
    projectionist_heuristics['lib/*.ex']['related'] = ["lib/" .. name .. ".ex"]

    call extend(projectionist_heuristics, {
        'lib/' .. name .. '_web.ex': {
          'type': 'web',
        },
        'lib/' .. name .. '_web/router.ex': {
          'type': 'router',
          'alternate': 'lib/' .. name .. '_web/endpoint.ex',
        },
        'lib/'. .. ame .. '_web/endpoint.ex': {
          'type': 'endpoint',
          'alternate': 'lib/' .. name .. '_web/router.ex'
        }
    })
  endif
