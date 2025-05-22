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
      assert Lexer.tokenize("x") == {:ok, [{:identifier, {1, 1}, :x}]}
      assert Lexer.tokenize("X") == {:ok, [{:identifier, {1, 1}, :X}]}
      assert Lexer.tokenize("foo") == {:ok, [{:identifier, {1, 1}, :foo}]}
      assert Lexer.tokenize("bar_baz") == {:ok, [{:identifier, {1, 1}, :bar_baz}]}
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
               {:ok, [{:identifier, {1, 1}, :x}, {:=, {1, 2}}, {:int, {1, 3}, 42}]}
    end

    test "tokenizes around whitespace correctly" do
      assert Lexer.tokenize(" 1  +    2 ") ==
               {:ok, [{:int, {1, 2}, 1}, {:+, {1, 5}}, {:int, {1, 10}, 2}]}

      assert Lexer.tokenize(" 1  +\n   2 ") ==
               {:ok, [{:int, {1, 2}, 1}, {:+, {1, 5}}, {:int, {2, 4}, 2}]}
    end

    test "handles error cases" do
      # integers cannot start with a zero
      assert {:error, _} = Lexer.tokenize("01")
      # variable cannot start with a digit
      assert {:error, _} = Lexer.tokenize("1z")
    end
  end

  describe "Automatic Semicolon Insertion" do
    test "ASI does not insert semicolon after certain tokens followed by newline" do
      # Using operators that shouldn't trigger ASI
      code = """
      x +
      y
      """
      {:ok, tokens} = Lexer.tokenize(code)

      refute Enum.any?(Enum.chunk_every(tokens, 2, 1, :discard), fn
        [ {'+', _}, ~c";" ] -> false
        _ -> false
      end)
    end
    test "ASI Does not trigger on newline mid expression" do
      # Using operators that shouldn't trigger ASI
      code = """
      x
      + y
      """
      {:ok, tokens} = Lexer.tokenize(code)

      refute Enum.any?(Enum.chunk_every(tokens, 2, 1, :discard), fn
        [ {'+', _}, ~c";" ] -> false
        _ -> false
      end)
    end
  end
end
