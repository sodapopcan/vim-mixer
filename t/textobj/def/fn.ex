defmodule Foo do
  def foo do
    "foo"
  end

  def bar do
    foo = 1
    baz = fn n -> n + 1 end

    baz.(foo)
  end
end
#_
# 8 11
# 8 14
# 8 27
# 9 1
# 10 10
# 11 1
#_
#%daf
defmodule Foo do
  def foo do
    "foo"
  end
end
#"

  def bar do
    foo = 1
    baz = fn n -> n + 1 end

    baz.(foo)
  end
#nl
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
    foo = 1
    baz = fn n -> n + 1 end

    baz.(foo)
#nl
