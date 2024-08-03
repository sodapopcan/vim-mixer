defmodule Foo do
  def foo do
    bar = "baz"
    biz = fn -> bar end
  end
end
#@@@
## Deletes a function
#~ normal daf
#.  2, 3
#.  3, 3
#.  5, 5
#%
defmodule Foo do
end
