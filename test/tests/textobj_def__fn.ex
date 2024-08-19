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
#@@@
## Changes inside a function
#~ normal cif"I'm new text"
#.  2,12
#.  3, 10
#.  4, 14
#.  5, 4
#%
defmodule Foo do
  def hi do
    "I'm new text"
  end
end
#@@@
## Replaces around a function
#~ normal caf"New text"
#.  3, 1
#%
defmodule Foo do
  "New text"
end
