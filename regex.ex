  if hi == "hi", do: "hi", else: "Oh hi!"
  if hi != "hi", do: "hi", else: "hi"
  if foo(hi), do: "hi", else: "hi"
  if foo(hi), do: "hi", else: "hi"
  foo: if("bar" > "baz" && if_foo < 2, do: some_call(foo), else: :if)
  foo: if "bar" > "baz" && if_foo < 2, do: some_call(foo = hi), else: :if
  %{foo: foo} = bar = if baz && if_foo < 2, do: some_call(foo), else: :if
  %{foo: foo} = bar = if baz || if_foo < 2, do: some_call(foo), else: :if
  %{foo: foo} = bar = if "bar" > "baz" && if_foo < 2, do: some_call(foo), else: :if
  %{foo: bar} -> if foo, do: some_call(foo), else: :if
  %{foo: bar} -> if do_it, do: some_call(foo), else: :if
  %{foo: bar} -> if do_it, do: some_call(foo), else: (
    if true, do: true, else: false
  )

if foo do
  maybe_ipv6 = if System.get_env("ECTO_IPV6", foo) in ~w(five true 1 five), do: [:inet6], else: foo in [true]
end

  if foo, do: (if foo, do: bar)

  custom foo,
    baz == baz,
    foo,
      do: "hi!"


  custom foo,
      baz == baz,
      biz when biz in [1,2,3,4,:foo],
      biz in [1,2,3,4],
      {:ok, biz} when biz in [one, two, three],
      ~w(true do when),
      when foo == "hi",

      bar(),

      foo() do
    fn -> "hi" end
  end


  custom(foo,
    baz == baz,
    foo,
      do: "hi!"
  )


  custom "custom foo bar baz",
    baz == baz,
    foo,
      do: "hi!"

  my_custom 1,
    baz == baz,
    foo,
      do: "hi!"

  custom do
    "hi"
  end

  [
    "hi",
    if true, do: "bar", else: "baz"
  ]
