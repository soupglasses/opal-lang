defmodule Opal.LexerTest do
  use ExUnit.Case
  doctest Opal.Lexer
  alias Opal.Lexer

  describe "tokenize/1" do
    test "tokenizes integers" do
      assert Lexer.tokenize("42") == {:ok, [{:int, {1, 1}, 42}]}
      assert Lexer.tokenize("0") == {:ok, [{:int, {1, 1}, 0}]}
      assert Lexer.tokenize("9999") == {:ok, [{:int, {1, 1}, 9999}]}
    end

    test "tokenizes floats" do
      assert Lexer.tokenize("3.14") == {:ok, [{:float, {1, 1}, 3.14}]}
      assert Lexer.tokenize("0.0") == {:ok, [{:float, {1, 1}, 0.0}]}
      assert Lexer.tokenize("42.0e3") == {:ok, [{:float, {1, 1}, 42000.0}]}
      assert Lexer.tokenize("42.0E+10") == {:ok, [{:float, {1, 1}, 420_000_000_000.0}]}
      assert Lexer.tokenize("42.0e-3") == {:ok, [{:float, {1, 1}, 0.042}]}
    end

    test "tokenizes identifiers" do
      assert Lexer.tokenize("x") == {:ok, [{:identifier, {1, 1}, :x}]}
      assert Lexer.tokenize("X") == {:ok, [{:identifier, {1, 1}, :X}]}
      assert Lexer.tokenize("foo") == {:ok, [{:identifier, {1, 1}, :foo}]}
      assert Lexer.tokenize("bar_baz") == {:ok, [{:identifier, {1, 1}, :bar_baz}]}
    end

    test "tokenizes simple expressions" do
      assert Lexer.tokenize("1 + 2") ==
               {:ok, [{:int, {1, 1}, 1}, {:+, {1, 3}}, {:int, {1, 5}, 2}]}

      assert Lexer.tokenize("x = 42") ==
               {:ok, [{:identifier, {1, 1}, :x}, {:=, {1, 3}}, {:int, {1, 5}, 42}]}
    end

    test "tokenizes around whitespace correctly" do
      assert Lexer.tokenize(" 1  +    2 ") ==
               {:ok, [{:int, {1, 2}, 1}, {:+, {1, 5}}, {:int, {1, 10}, 2}]}

      assert Lexer.tokenize(" 1  +\n   2 ") ==
               {:ok, [{:int, {1, 2}, 1}, {:+, {1, 5}}, {:int, {2, 4}, 2}]}
    end

    test "handles error cases" do
      assert {:error, _} = Lexer.tokenize("1z")
    end
  end
end
