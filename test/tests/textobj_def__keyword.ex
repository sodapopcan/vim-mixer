  if hi == "hi", do: "hi", else: "Oh hi!"
  if hi != "hi", do: "hi", else: "hi"
  if foo(hi), do: "hi", else: "hi"
  if foo(hi), do: "hi", else: "hi"
  foo: if("bar" > "baz" && if_foo < 2, do: some_call(foo), else: :if),
  foo: if "bar" + "baz" && if_foo < 2, do: some_call(foo = hi), else: :if
  %{foo: foo} = bar = if baz && 1 - 2 * 12 / if_foo + 2, do: some_call(foo), else: foo()
  %{foo: foo} = bar = if baz || if_foo < 2, do: some_call(foo), else: :if
  %{foo: foo} = bar = if "bar" > "baz" && if_foo < 2, do: some_call(foo), else: :if
  %{foo: bar} -> if foo, do: some_call(foo), else: :i
  %{foo: bar} -> if do_it, do: some_call(foo), else: :if
  %{foo: bar} -> if do_it, do: some_call(foo), else: (
    if true, do: true, else: false
  )

  [1, 2, if(true, do: 3, else: 4)]

if foo do
  maybe_ipv6 = if System.get_env("ECTO_IPV6", foo) in ~w(five true 1 five),
    do: foo([:inet6], "bar"),
    else: foo in [true]
end

  if foo(), do: [
    1, 2, 3, 4
  ],
  else: %{
    foo: "bar"
  }

  for foo <- [1,2,3,4,5],
    reduce: [],
    into: %{},
    do: "foo"

  if foo, do: (if foo, do: bar)

  foo = if foo() do
    true
  else
    false
  end

  custom foo,
    baz == baz,
    foo,
      do: "hi!"

  Foo.Bar.custom foo,
    baz == baz,
    foo,
      do: "hi!"

  Foo.Bar.custom_func(foo,
    baz == baz,
    foo,
      do: "hi!")

  :foo.foo do
    "hi"
  end

  customFunc foo,
      baz == baz,
      biz when biz in [1,2,3,4,:foo],
      biz not in [1,2,3,4],
      {:ok, biz} when biz in [one, two, three],
      ~w(true do when),
      when foo == "hi",

      A.bar(),

      foo do
    fn -> "hi" end
  end

  foo foo,
    ~w[a b c d e]
  do
  end


  %{bar: bar} = foo = if bar = baz && false do
    true
  else
    false
  end

  # Hi there
  # I'm a comment
  %{bar: bar} =
    if bar = baz && false do
      true
    else
      false
    end

  %{
    bar: bar
  } =
    if bar = baz && false do
      true
    else
      false
    end

  foo = if true do
    true
  else
    false
  end

  baz do
    "hi"
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
      do: foo([1, 2, 3, 4], "foo", :bar),
      else: "hi",
      else: :atom,
      else: %Struct{},
      else: ~S"""

      """,
      custom do
    "hi"
  end

  if custom do
    "hi"
  end


  custom do
    "hi"
  end

  [
    "hi",
    if true, do: "bar", else: "baz"
  ]

  {["hi", if true, do: "bar", else: "baz"]}
  %{hi: "hi", foo: if true, do: foo(), else: foo()}

  %{foo: "foo", bar: foo do: foo(), else: [1,2,3,4]}

#@@@
