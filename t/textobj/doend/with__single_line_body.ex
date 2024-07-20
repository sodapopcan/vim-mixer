defmodule Foo do
  def foo do
    with {:ok, foo} <- foo() do
      foo
    end
  end
end
#_
# 3 5
# 3 31
# 5 7
# 4 8
#_
#%dad
defmodule Foo do
  def foo do
  end
end
#"
    with {:ok, foo} <- foo() do
      foo
    end
#nl
#_
#%did
defmodule Foo do
  def foo do
    with {:ok, foo} <- foo() do
    end
  end
end
#"
      foo
#nl
