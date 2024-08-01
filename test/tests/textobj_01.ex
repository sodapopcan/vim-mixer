defmodule Foo do
  @moduledoc """
  This is a test module doc.

  This is a new line as it might span several lines.

  And here
    - Are
    - some
    - bullet points
  """

  @spec foo :: String.t()
  def foo do
    "foo"
  end

  @doc """
  I'm a doc.

  ## Example

      iex> bar(%Foo{})
      %Foo{bar: "baz"}

  There is a space between me and the @spec
  """

  @spec bar(Foo.t()) :: Baz.t()
  def bar(foo) when is_number(foo) do
    foo = foo + 1
    baz = fn n -> n + 1 end

    baz.(foo)
  end

  def bar("1") do
    "one"
  end

  def bar("two"), do: "two"

  def baz("bizzzzz"), do: "Sure"
end
#===
#~ normal daf
#.  30, 3
#%
defmodule Foo do
  def foo do
    "foo"
  end
end
