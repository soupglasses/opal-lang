module Math do
  fn sign(x) do
    if x < 0 then
      -1
    else
      1
    end
  end

  fn main([]) do main(["-50"]) end
  fn main([num]) do
    :io.format("~p~n",
      [sign(:erlang.list_to_integer(num))]
    )
  end
end
