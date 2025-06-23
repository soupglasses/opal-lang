module List do
  fn length([]) do 0 end
  fn length([_|tail]) do 1 + length(tail) end

  fn reverse([], acc) do acc end
  fn reverse([head | tail], acc) do reverse(tail, [head | acc]) end
  fn reverse(list) do reverse(list, []) end

  fn map(_, []) do [] end
  fn map(fun, [head | tail]) do
    [fun(head) | map(fun, tail)]
  end

  fn map_tail(fun, [], acc) do reverse(acc) end
  fn map_tail(fun, [head | tail], acc) do
    map_tail(fun, tail, [fun(head), acc])
  end
  fn map_tail(fun, list) do map_tail(fun, list, []) end

  fn main(args) do
    :io.format("~p~n", [length([1,2,3,4,5,6,7,8,9,10])]);
    :io.format("~p~n",
      [reverse([?!, ?d, ?l, ?r, ?o, ?W, ? , ?o, ?l, ?l, ?e, ?H])]
    )
  end
end
