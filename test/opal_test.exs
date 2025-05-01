defmodule OpalTest do
  use ExUnit.Case
  doctest Opal

  test "sanity tokenize" do
    assert Opal.Lexer.tokenize("1 + 2") ==
             {:ok, [{:int, {1, 1}, 1}, {:+, {1, 3}}, {:int, {1, 5}, 2}]}
  end

  test "sanity parse" do
    assert Opal.Parser.parse([{:int, {1, 1}, 1}, {:+, {1, 3}}, {:int, {1, 5}, 2}]) ==
             {:ok, {:add, {:int, 1}, {:int, 2}}}
  end

  test "sanity run" do
    assert Opal.Compiler.run({:add, {:int, 1}, {:int, 2}}) == 3
  end
end
