defmodule Foo do
  def foo do
    "foo"
  end

  def bar do
    baz
  end
end
#_
# 2 3
# 2 9
# 3 5
# 4 3
#_
#%daf
defmodule Foo do

  def bar do
    baz
  end
end
#"
  def foo do
    "foo"
  end
#empty
#_
#%dif
defmodule Foo do
  def foo do
  end

  def bar do
    baz
  end
end
#"
    "foo"
#empty
