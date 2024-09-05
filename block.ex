foo do
  hi
end

foo "hi" do
  "hi"
end

foo, do: (
  "hi"
)

foo "hi", do: (
  "hi"
)

foo do: [
  "hi"
]

foo do: {
  :hi
}

Foo.map()

  def foo do

  end

  def foo do
    "hi"
  end

  def foo do
    if true do
      fn -> true end
      false
    end
  end

  (def foo, do: [
    "hi", "bye"
    ])

  defmacrop do_foo(hi),
    do: foo && bar
