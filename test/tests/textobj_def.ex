defmodule Foo do
  def hi do
    "hi"
  end
end
#@@@
## Deletes a function
#~ normal daf
#.  2, 3
#.  2, 3
#%
defmodule Foo do
end
#@@@
## Does nothing when cursor is after function
#~ normal daf
#.  5, 1
#%
defmodule Foo do
  def hi do
    "hi"
  end
end
#@@@
## Changes inside a function
#~ normal cif"I'm new text"
#.  2,11
#.  3, 1
#.  4, 2
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
