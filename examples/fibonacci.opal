module Fibonacci do
  fn fib(0) do 0 end
  fn fib(1) do 1 end
  fn fib(x) do
    fib(x - 1) + fib(x - 2)
  end

  fn main([]) do main(["10"]) end
  fn main([num]) do
    :io.format("~p~n",
      [fib(:erlang.list_to_integer(num))]
    )
  end
end
