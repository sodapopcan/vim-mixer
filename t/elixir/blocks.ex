#T string_is_func_name
hello "hello" do
  true
end

#T multi_line_with_single_map
some_var %{
  hi: "hi",
  some_var: "some_var"
} do
  true
end

some_var(
  %{hi: "hi"},
  %{some_var: "some_var"},
  some_arg
) do
  true
end

some_fun(
  %{hi: "hi!"},
  %{eq: "="},
  another_arg
) do
  some("body")
end

#T multi_arg_without_parens
some_var "some_var", arg2, arg3 do
  true
end

#T nested
nested do
  nested(
    nested("aritst"), :atom, [:a, 1, "a"]
  ) do
end

nested nested("nested") do
  nested
end

nested(nested("nested")) do
  nested
end

nested(nested("nested"), "foo") do
  nested
end

#T test
test "test that it does the thing", %{some: test} do
  assert "test"
end

#T
%{if: "if"} = foo = if true do
  assert "test"
  assert "test"
  assert "test"
  assert "test"
  assert "test"
  assert "test"
end

foo =
  if bar do
    true
  else
    false
  end

defp get_q(params) do
  if q = Map.get(params, "q") do
    if String.trim(q) == "" do
      nil
    else
      q
    end
  end
end

case some_call("hi there") do
  %{foo: "bar"} -> if true do
      "yaya"
  end
end

def foo "b" = a do
  a
end

with nil <- Desj.Wishlists.get_current_wishlist(current_user),
     {:ok, wishlist} = Desj.Wishlists.create_wishlist(current_user) do
  wishlist
end
