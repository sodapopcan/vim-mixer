defmodule Foo do
  @doc """
  I'm some docs.

  There's a blank line.
  """

  @spec foo() :: String.t()
  def foo do
    "foo"
  end
end
#_
# 2 3
# 7 1
# 8 21
# 9 3
# 9 12
# 11 1
#_
#%daF
defmodule Foo do
end
#"
  @doc """
  I'm some docs.

  There's a blank line.
  """

  @spec foo() :: String.t()
  def foo do
    "foo"
  end
#_
#%diF
defmodule Foo do
  @doc """
  I'm some docs.

  There's a blank line.
  """

  @spec foo() :: String.t()
  def foo do
  end
end
#"
    "foo"
