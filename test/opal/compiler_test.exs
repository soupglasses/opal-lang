defmodule Opal.CompilerTest do
  use ExUnit.Case
  doctest Opal.Compiler
  # alias Opal.Compiler

  describe "generate_core/1" do
    test "pattern matching" do
      assert 1 == Opal.run("x = 1")
      assert 1 == Opal.run("1 = 1")
      assert 1 == Opal.run("x = 1 ; 1 = x")
      assert 42 == Opal.run("x = 1; 1 = x; 42 = 42")
    end

    test "wildcard" do
      # TODO: Does not properly test wildcard, needs tuple or list in pattern.
      assert 42 == Opal.run("_ = 42", compiler_opts: [])
    end

    test "assignment" do
      assert 42 == Opal.run("x = 42", compiler_opts: [])
      assert 42 == Opal.run("x = 42; 69; x", compiler_opts: [])
    end

    test "pattern matching lists" do
      # Empty
      assert [] == Opal.run("[] = []")
      assert [] == Opal.run("x = []; x")

      # Random
      assert [42] == Opal.run("[x] = [42]")
      assert :atom == Opal.run("[x] = [:atom]; x")
      assert [2, 3] == Opal.run("[1 | x] = [1,2,3]; x")
      assert 3 == Opal.run("[1, _, x] = [1,2,3]; x")

      # Head/Tail
      assert 1 == Opal.run("[h | _] = [1,2,3]; h")
      assert [2, 3] == Opal.run("[_ | t] = [1,2,3]; t")
      assert [3, 4, 5] == Opal.run("[_, _ | rest] = [1,2,3,4,5]; rest")

      # Use variables
      assert {1, [2, 3]} == Opal.run("[a | b] = [1,2,3]; {a, b}")
      assert {1, 2, [3]} == Opal.run("[x, y | z] = [1,2,3]; {x, y, z}")

      # Nested lists
      assert 4 == Opal.run("[[_, x] | _] = [[3,4], [5,6]]; x")
      assert [5, 6] == Opal.run("[_ | [y]] = [[3,4], [5,6]]; y")
    end

    test "pattern matching tuples" do
      # Basic variables
      assert {1, 2} == Opal.run("{x, y} = {1, 2}")
      assert 1 == Opal.run("{x, _} = {1, 2}; x")
      assert 2 == Opal.run("{_, y} = {1, 2}; y")

      # Tuple with different types
      assert {:ok, 42} == Opal.run("{status, value} = {:ok, 42}; {status, value}")
      assert ~c"hello" == Opal.run("{:ok, msg} = {:ok, \"hello\"}; msg")
      assert :error == Opal.run("{status, _} = {:error, \"failed\"}; status")
    end

    test "nil" do
      assert nil == Opal.run("nil")
    end

    test "trail of thought not lost" do
      assert 42 == Opal.run("x = 42; 1; 2; 3; 4; 5; x", compiler_opts: [])
    end

    test "unary operators" do
      assert false == Opal.run("not true")
      assert -42 == Opal.run("-42")
    end

    test "booleans" do
      assert false == Opal.run("true and false")
      assert true == Opal.run("false or true")
    end

    test "short-circuiting logical operators" do
      assert true == Opal.run("1 < 2 and 3 < 4")
      assert true == Opal.run("2 < 1 or 3 < 4")
      assert true == Opal.run("true or 1 / 0", compiler_opts: [])
      assert false == Opal.run("false and 1 / 0", compiler_opts: [])
    end

    test "lists" do
      assert [] == Opal.run("[]")
      assert [1] == Opal.run("[1]")
      assert [1, 2] == Opal.run("[1, 2]")

      assert [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20] ==
               Opal.run("[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]")
    end

    test "nested lists" do
      assert [[]] == Opal.run("[[]]")
      assert [[1]] == Opal.run("[[1]]")
      assert [[1], [2]] == Opal.run("[[1], [2]]")
      assert [[1, 2], [3]] == Opal.run("[[1, 2], [3]]")
    end

    test "cons lists" do
      assert [1] == Opal.run("[1 | []]")
      assert [1, 2] == Opal.run("[1 | [2 | []]]")
      assert [1, 2, 3] == Opal.run("[1 | [2 | [3 | []]]]")
    end

    test "cons lists and lists are equivalent" do
      assert Opal.run("[1,2,3,4]") == Opal.run("[1 | [2 | [3 | [4 | []]]]]")
      assert Opal.run("[1, [2 | [3 | [4 | []]]]]") == Opal.run("[1 | [[2,3,4]]]")
      assert [1, 2, 3, 4] == Opal.run("[1, 2 | [3,4]]")
    end

    test "tuples" do
      assert {} == Opal.run("{}")
      assert {1} == Opal.run("{1}")
      assert {1, 2} == Opal.run("{1,2}")
      assert {1, 2, 3, 4, 5, 6, 7, 8, 9, 10} == Opal.run("{1,2,3,4,5,6,7,8,9,10}")
    end

    test "string" do
      assert ~c"Hello world!" == Opal.run("\"Hello world!\"")
    end

    test "chars" do
      assert ?" == Opal.run("?\"")
    end

    test "equality" do
      assert true == Opal.run("1 < 2")
      assert false == Opal.run("1 < 1")
      assert true == Opal.run("1 <= 2")
      assert true == Opal.run("1 <= 1")
      assert true == Opal.run("2 > 1")
      assert false == Opal.run("1 > 1")
      assert true == Opal.run("2 >= 1")
      assert true == Opal.run("1 >= 1")
      assert true == Opal.run("1 == 1")
      assert false == Opal.run("1 != 1")
    end

    test "function argument order" do
      assert true ==
               Opal.run("""
               fn leq(l, r) do
                 l <= r
               end

               leq(1, 2)
               """)
    end

    test "run external funcs" do
      assert 0.00000 == Float.round(Opal.run("pi = :math.pi(); :math.sin(pi)"), 5)
      # assert 0.00000 == Float.round(Opal.run(":math.sin(:math.pi())"), 5)
    end

    test "run internal funcs" do
      assert 42 == Opal.run("fn answer_to_everything() do 42 end answer_to_everything()")
      assert 42 == Opal.run("fn answer_to_everything(x) do x end answer_to_everything(42)")
    end

    test "pattern matching in funcs" do
      assert 10 ==
               Opal.run("""
                 fn length([]) do 0 end
                 fn length([_|t]) do 1 + length(t) end

                 length([1,2,3,4,5,6,7,8,9,10])
               """)

      assert [4, 3, 2, 1] ==
               Opal.run("""
                 fn reverse([], acc) do acc end
                 fn reverse([head | tail], acc) do
                    reverse(tail, [head | acc])
                 end

                 reverse([1,2,3,4], [])
               """)
    end

    test "handles error cases" do
      # We cannot read the wildcard
      assert {:error, _, _} = Opal.run("_ = 42; 69; _", compiler_opts: [])
    end
  end
end
