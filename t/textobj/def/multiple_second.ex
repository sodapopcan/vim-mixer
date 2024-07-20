defmodule Foo do
  def foo do
    "foo"
  end

  def bar do
    "hi there"
  end
end
#_
# 6 3
# 6 8
# 6 12
# 7 0
# 8 3
#_
#%daf
defmodule Foo do
  def foo do
    "foo"
  end
end
#"

  def bar do
    "hi there"
  end
#empty
#_
#%dif
defmodule Foo do
  def foo do
    "foo"
  end

  def bar do
  end
end
#"
    "hi there"
#empty
