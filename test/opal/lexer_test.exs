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

    test "tokenizes strings" do
      assert Lexer.tokenize("\"Hello world!\nHow is your day going?\"") ==
               {:ok, [{:string, {1, 1}, ~c"Hello world!\nHow is your day going?"}]}
    end

    test "tokenizes char" do
      assert Lexer.tokenize("?\"") == {:ok, [{:char, {1, 1}, ?"}]}
      assert Lexer.tokenize("?a") == {:ok, [{:char, {1, 1}, 97}]}
    end

    test "tokenizes lists" do
      assert Lexer.tokenize("[]") == {:ok, [{:"[", {1, 1}}, {:"]", {1, 2}}]}
      assert Lexer.tokenize("[1]") == {:ok, [{:"[", {1, 1}}, {:int, {1, 2}, 1}, {:"]", {1, 3}}]}

      assert Lexer.tokenize("[1, 2]") ==
               {:ok,
                [
                  {:"[", {1, 1}},
                  {:int, {1, 2}, 1},
                  {:",", {1, 3}},
                  {:int, {1, 5}, 2},
                  {:"]", {1, 6}}
                ]}

      assert Lexer.tokenize("[1 | []]") ==
               {:ok,
                [
                  {:"[", {1, 1}},
                  {:int, {1, 2}, 1},
                  {:|, {1, 4}},
                  {:"[", {1, 6}},
                  {:"]", {1, 7}},
                  {:"]", {1, 8}}
                ]}

      assert Lexer.tokenize("[1 | [2 | []]]") ==
               {:ok,
                [
                  {:"[", {1, 1}},
                  {:int, {1, 2}, 1},
                  {:|, {1, 4}},
                  {:"[", {1, 6}},
                  {:int, {1, 7}, 2},
                  {:|, {1, 9}},
                  {:"[", {1, 11}},
                  {:"]", {1, 12}},
                  {:"]", {1, 13}},
                  {:"]", {1, 14}}
                ]}
    end

    test "tokenizes tuples" do
      assert Lexer.tokenize("{}") == {:ok, ["{": {1, 1}, "}": {1, 2}]}
      assert Lexer.tokenize("{1}") == {:ok, [{:"{", {1, 1}}, {:int, {1, 2}, 1}, {:"}", {1, 3}}]}

      assert Lexer.tokenize("{1, 2}") ==
               {:ok,
                [
                  {:"{", {1, 1}},
                  {:int, {1, 2}, 1},
                  {:",", {1, 3}},
                  {:int, {1, 5}, 2},
                  {:"}", {1, 6}}
                ]}
    end

    test "tokenizes nil" do
      assert Lexer.tokenize("nil") == {:ok, [{nil, {1, 1}}]}
    end

    test "tokenizes if conditions" do
      assert Lexer.tokenize("if true then 42 else 69 end") ==
               {:ok,
                [
                  {:if, {1, 1}},
                  {:bool, {1, 4}, true},
                  {:then, {1, 9}},
                  {:int, {1, 14}, 42},
                  {:else, {1, 17}},
                  {:int, {1, 22}, 69},
                  {:end, {1, 25}}
                ]}

      assert Lexer.tokenize("if (10 <= 20) then 42 else 69 end") ==
               {
                 :ok,
                 [
                   {:if, {1, 1}},
                   {:"(", {1, 4}},
                   {:int, {1, 5}, 10},
                   {:<=, {1, 8}},
                   {:int, {1, 11}, 20},
                   {:")", {1, 13}},
                   {:then, {1, 15}},
                   {:int, {1, 20}, 42},
                   {:else, {1, 23}},
                   {:int, {1, 28}, 69},
                   {:end, {1, 31}}
                 ]
               }
    end

    test "handles error cases" do
      # integers cannot start with a zero
      assert {:error, _} = Lexer.tokenize("01")
      # variable cannot start with a digit
      assert {:error, _} = Lexer.tokenize("1z")
    end
  end
end
