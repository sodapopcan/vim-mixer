defmodule Foo do
  def foo do
    with {:ok, foo} <- foo(),
         true <- some_other_thing({:a, :tuple}),
         {:ok, long_variable_name} <-
           longer_function_name_call(argument_1, argument_2, argument_3) do
      foo = long_variable_name
      foo
    end
  end
end
#_
# 3 0
# 6 74
# 9 3
# 6 12
#_
#%dad
defmodule Foo do
  def foo do
  end
end
#"
    with {:ok, foo} <- foo(),
         true <- some_other_thing({:a, :tuple}),
         {:ok, long_variable_name} <-
           longer_function_name_call(argument_1, argument_2, argument_3) do
      foo = long_variable_name
      foo
    end
#nl
#_
#%did
defmodule Foo do
  def foo do
    with {:ok, foo} <- foo(),
         true <- some_other_thing({:a, :tuple}),
         {:ok, long_variable_name} <-
           longer_function_name_call(argument_1, argument_2, argument_3) do
    end
  end
end
#"
      foo = long_variable_name
      foo
#nl
