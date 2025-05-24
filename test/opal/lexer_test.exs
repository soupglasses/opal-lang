defmodule Opal.LexerTest do
  use ExUnit.Case
  doctest Opal.Lexer
  alias Opal.Lexer

  describe "tokenize/1" do
    test "tokenizes integers" do
      assert Lexer.tokenize("42") == {:ok, [{:int, {1, 1}, 42}]}
      assert Lexer.tokenize("0") == {:ok, [{:int, {1, 1}, 0}]}
      assert Lexer.tokenize("9999") == {:ok, [{:int, {1, 1}, 9999}]}
      assert Lexer.tokenize("100_000") == {:ok, [{:int, {1, 1}, 100_000}]}
    end

    test "tokenizes floats" do
      assert Lexer.tokenize("3.14") == {:ok, [{:float, {1, 1}, 3.14}]}
      assert Lexer.tokenize("0.0") == {:ok, [{:float, {1, 1}, 0.0}]}
      assert Lexer.tokenize("42.0e3") == {:ok, [{:float, {1, 1}, 42000.0}]}
      assert Lexer.tokenize("42.0E+10") == {:ok, [{:float, {1, 1}, 420_000_000_000.0}]}
      assert Lexer.tokenize("42.0e-3") == {:ok, [{:float, {1, 1}, 0.042}]}
    end

    test "tokenizes identifiers" do
      assert Lexer.tokenize("x") == {:ok, [{:var, {1, 1}, :x}]}
      assert Lexer.tokenize("foo") == {:ok, [{:var, {1, 1}, :foo}]}
      assert Lexer.tokenize("bar_baz") == {:ok, [{:var, {1, 1}, :bar_baz}]}
    end

    test "tokenizes around comments" do
      assert Lexer.tokenize("42 # The answer to life, the universe, and everything") ==
               {:ok, [{:int, {1, 1}, 42}]}

      assert Lexer.tokenize("# What is 9 + 10?\n21") ==
               {:ok, [{:int, {2, 1}, 21}]}
    end

    test "tokenizes simple expressions" do
      assert Lexer.tokenize("1+2") ==
               {:ok, [{:int, {1, 1}, 1}, {:+, {1, 2}}, {:int, {1, 3}, 2}]}

      assert Lexer.tokenize("x=42") ==
               {:ok, [{:var, {1, 1}, :x}, {:=, {1, 2}}, {:int, {1, 3}, 42}]}
    end

    test "tokenizes around whitespace correctly" do
      assert Lexer.tokenize(" 1  +    2 ") ==
               {:ok, [{:int, {1, 2}, 1}, {:+, {1, 5}}, {:int, {1, 10}, 2}]}

      assert Lexer.tokenize(" 1  +\n \n   2 ") ==
               {:ok, [{:int, {1, 2}, 1}, {:+, {1, 5}}, {:int, {3, 4}, 2}]}

      assert Lexer.tokenize(" 1  +\n \n    \r\n   2 ") ==
               {:ok, [{:int, {1, 2}, 1}, {:+, {1, 5}}, {:int, {4, 4}, 2}]}
    end

    # TODO: Module Identifiers
    # TODO: Functions
    # TODO: Function calls

    test "handles error cases" do
      # integers cannot start with a zero
      assert {:error, _} = Lexer.tokenize("01")
      # variable cannot start with a digit
      assert {:error, _} = Lexer.tokenize("1z")
    end
  end
end
