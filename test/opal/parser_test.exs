defmodule Opal.ParserTest do
  use ExUnit.Case
  doctest Opal.Parser
  alias Opal.Parser

  describe "parse/1" do
    test "parses integer literals" do
      assert Parser.parse([{:int, {1, 1}, 42}]) == {:ok, [{:int, {1, 1}, 42}]}
    end

    test "parses float literals" do
      assert Parser.parse([{:float, {1, 1}, 3.14}]) == {:ok, [{:float, {1, 1}, 3.14}]}
    end

    test "parses binary expressions" do
      tokens = [{:int, {1, 1}, 1}, {:+, {1, 3}}, {:int, {1, 5}, 2}]
      assert Parser.parse(tokens) == {:ok, [{:add, {:int, {1, 1}, 1}, {:int, {1, 5}, 2}}]}

      tokens = [{:int, {1, 1}, 3}, {:-, {1, 3}}, {:int, {1, 5}, 4}]
      assert Parser.parse(tokens) == {:ok, [{:subtract, {:int, {1, 1}, 3}, {:int, {1, 5}, 4}}]}

      tokens = [{:int, {1, 1}, 5}, {:*, {1, 3}}, {:int, {1, 5}, 6}]
      assert Parser.parse(tokens) == {:ok, [{:multiply, {:int, {1, 1}, 5}, {:int, {1, 5}, 6}}]}

      tokens = [{:int, {1, 1}, 8}, {:/, {1, 3}}, {:int, {1, 5}, 2}]
      assert Parser.parse(tokens) == {:ok, [{:divide, {:int, {1, 1}, 8}, {:int, {1, 5}, 2}}]}
    end

    test "parses operator precedence" do
    end

    test "parses parenthesized expressions" do
    end

    test "parses variable assignments" do
    end

    test "parses pattern matching assignments" do
    end

    test "parses variable references" do
    end

    test "parses statements with semicolons" do
    end

    test "handles error cases" do
    end
  end
end
