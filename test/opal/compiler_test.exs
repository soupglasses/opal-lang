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

    test "trail of thought not lost" do
      assert 42 == Opal.run("x = 42; 1; 2; 3; 4; 5; x")
    end

    test "unary operators" do
      assert false == Opal.run("not true")
      assert -42 == Opal.run("-42")
    end

    test "booleans" do
      assert false == Opal.run("true and false")
      assert true == Opal.run("false or true")
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
