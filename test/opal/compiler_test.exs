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
      assert 42 == Opal.run("_ = 42")
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
      # assert [1, 2, 3, 4] == Opal.run("[1, 2 | [3,4]]")
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

    test "run external funcs" do
      assert 0.00000 == Float.round(Opal.run("pi = :math.pi(); :math.sin(pi)"), 5)
      # assert 0.00000 == Float.round(Opal.run(":math.sin(:math.pi())"), 5)
    end

    test "run internal funcs" do
      assert 42 == Opal.run("fn answer_to_everything() do 42 end answer_to_everything()")
      assert 42 == Opal.run("fn answer_to_everything(x) do x end answer_to_everything(42)")
    end

    test "handles error cases" do
      # ast = {:unknown_node_type, 42}
      # assert {:error, _} = Compiler.generate_core(ast)
    end
  end
end
