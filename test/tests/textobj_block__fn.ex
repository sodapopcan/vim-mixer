defmodule Foo do
  def foo do
    bar = fn -> "baz" end

    bar.()
  end

  def get_base_users do
    emails = @base_users |> Enum.map(fn user ->
      user[:email]
    end)

    User
    |> where([m], m.email in ^emails)
    |> Repo.all()
  end
end
#@@@
## Works with fn
#~ normal dad
#.  3,14
#%
defmodule Foo do

  def get_base_users do
    emails = @base_users |> Enum.map(fn user ->
      user[:email]
    end)

    User
    |> where([m], m.email in ^emails)
    |> Repo.all()
  end
end
#@@@
## Still works with fn
#~ normal dad
#. 10,10
#%
defmodule Foo do
  def foo do
    bar = fn -> "baz" end

    bar.()
  end
  end
