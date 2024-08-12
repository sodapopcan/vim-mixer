defmodule Foo do
  def foo do
    bar = fn -> "baz" end

    bar.()
  end

  def foo do
    "hi"
  end
end
#@@@
## Works with fn
#~ normal dad
#.  3,14
#%
defmodule Foo do

  def foo do
    "hi"
  end
end
