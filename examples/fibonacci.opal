module Fibonacci do
  fn fib(0) do 0 end
  fn fib(1) do 1 end
  fn fib(x) do
    fib(x - 1) + fib(x - 2)
  end

  fn main(args) do
    :io.put_chars(
      :erlang.integer_to_list(fib(
        :erlang.list_to_integer(:erlang.hd(args))
      ))
    )
  end
end
