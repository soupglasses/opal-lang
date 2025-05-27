defmodule Opal.ParserTest do
  use ExUnit.Case
  doctest Opal.Parser
  alias Opal.Parser
  alias Opal.Lexer

  describe "parse/1" do
    test "parses integer literals" do
      assert Parser.parse(Lexer.tokenize!("42")) == {:ok, [[{:int, {1, 1}, 42}]]}
    end

    test "parses float literals" do
      assert Parser.parse(Lexer.tokenize!("3.14")) == {:ok, [[{:float, {1, 1}, 3.14}]]}
    end

    test "parses binary expressions" do
      assert Parser.parse(Lexer.tokenize!("1 + 2")) ==
               {:ok, [[{{:+, {1, 3}}, {:int, {1, 1}, 1}, {:int, {1, 5}, 2}}]]}

      assert Parser.parse(Lexer.tokenize!("3 - 4")) ==
               {:ok, [[{{:-, {1, 3}}, {:int, {1, 1}, 3}, {:int, {1, 5}, 4}}]]}

      assert Parser.parse(Lexer.tokenize!("5 * 6")) ==
               {:ok, [[{{:*, {1, 3}}, {:int, {1, 1}, 5}, {:int, {1, 5}, 6}}]]}

      assert Parser.parse(Lexer.tokenize!("8 / 2")) ==
               {:ok, [[{{:/, {1, 3}}, {:int, {1, 1}, 8}, {:int, {1, 5}, 2}}]]}

      assert Parser.parse(Lexer.tokenize!("8 % 2")) ==
               {:ok, [[{{:%, {1, 3}}, {:int, {1, 1}, 8}, {:int, {1, 5}, 2}}]]}
    end

    test "parses operator precedence" do
      rhs = {{:*, {1, 7}}, {:int, {1, 5}, 3}, {:int, {1, 9}, 4}}

      assert Parser.parse(Lexer.tokenize!("2 + 3 * 4")) ==
               {:ok, [[{{:+, {1, 3}}, {:int, {1, 1}, 2}, rhs}]]}
    end

    test "parses parenthesized expressions" do
      lhs = {{:+, {1, 4}}, {:int, {1, 2}, 2}, {:int, {1, 6}, 3}}

      assert Parser.parse(Lexer.tokenize!("(2 + 3) * 4")) ==
               {:ok, [[{{:*, {1, 9}}, lhs, {:int, {1, 11}, 4}}]]}
    end

    test "parses around newlines" do
      assert Parser.parse(Lexer.tokenize!("2 + \n 3")) ==
               {:ok, [[{{:+, {1, 3}}, {:int, {1, 1}, 2}, {:int, {2, 2}, 3}}]]}
    end

    test "can handle multiple newline statements" do
      assert Parser.parse(Lexer.tokenize!("fn test() do 4;\n 3\n\n;\n 2 end")) ==
               {:ok,
                [
                  {:function, {1, 1},
                   {{:var, {1, 4}, :test}, {:patterns, []},
                    [{:int, {1, 14}, 4}, {:int, {2, 2}, 3}, {:int, {5, 2}, 2}]}}
                ]}

      assert Parser.parse(Lexer.tokenize!("fn test() do\n 4 end")) ==
               {:ok,
                [
                  {:function, {1, 1},
                   {{:var, {1, 4}, :test}, {:patterns, []}, [{:int, {2, 2}, 4}]}}
                ]}

      assert Parser.parse(Lexer.tokenize!("fn test() do\n 4 +\n 3 end")) ==
               {:ok,
                [
                  {:function, {1, 1},
                   {{:var, {1, 4}, :test}, {:patterns, []},
                    [
                      {{:+, {2, 4}}, {:int, {2, 2}, 4}, {:int, {3, 2}, 3}}
                    ]}}
                ]}

      assert Parser.parse(Lexer.tokenize!("fn test() do \n 4;\n 3 \n end")) ==
               {:ok,
                [
                  {:function, {1, 1},
                   {{:var, {1, 4}, :test}, {:patterns, []},
                    [
                      {:int, {2, 2}, 4},
                      {:int, {3, 2}, 3}
                    ]}}
                ]}
    end

    test "boolean algebra" do
      assert Parser.parse(Lexer.tokenize!("2 < 3")) ==
               {:ok, [[{{:<, {1, 3}}, {:int, {1, 1}, 2}, {:int, {1, 5}, 3}}]]}
    end

    test "parses nil" do
      assert Parser.parse(Lexer.tokenize!("nil")) ==
               {:ok, [[{:nil, {1, 1}}]]}
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
