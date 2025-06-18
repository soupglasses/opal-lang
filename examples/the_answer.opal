module TheAnswer do
  fn calculate() do
    42
  end

  fn main(args) do
    :io.put_chars(:erlang.integer_to_list(calculate()))
  end
end
