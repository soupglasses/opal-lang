defmodule Opal.IntegrationTest do
  use ExUnit.Case
  doctest Opal

  describe "full integration" do
    test "evaluates basic arithmetic expressions" do
      assert Opal.run("1 + 2") == 3
      assert Opal.run("1 - 2") == -1
      assert Opal.run("2 * 3") == 6
      assert Opal.run("10 / 2") == 5.0
    end

    test "evaluates operator precedence" do
      assert Opal.run("1 + 2 * 3") == 7
      assert Opal.run("(1 + 2) * 3") == 9
      assert Opal.run("10 - 2 * 3") == 4
    end

    test "evaluates floating point arithmetic" do
      assert Opal.run("3.14 + 2.86") == 6.0
      assert Opal.run("5.5 * 2.0") == 11.0
    end

    test "evaluates mixed integer and float arithmetic" do
      assert Opal.run("3 + 2.5") == 5.5
      assert Opal.run("2.5 - 3") == -0.5
      assert Opal.run("2 * 3.5") == 7.0
      assert Opal.run("5 / 2.5") == 2.0
    end

    test "evaluates assignment and reference" do
      assert Opal.run("x = 42; x") == 42
      assert Opal.run("x = 1; y = 2; x + y") == 3
      # Variable reassignment
      assert Opal.run("x = 1; x = 2; x") == 2
    end

    test "evaluates pattern matching" do
      assert Opal.run("x = 42; 42 = x; 42") == 42
    end

    test "evaluates scoping rules for variables" do
    end

    test "evaluates recursive functions" do
    end

    test "handles errors gracefully" do
      # FIX: Parser error is 2 args, Compiler error is 3 args. Runtime is exception.
      # Incomplete expression
      assert {:error, _} = Opal.run("1 +")
      # Undefined variable
      assert {:error, _, _} = Opal.run("x")
      # Division by zero
      assert {:error, _} = Opal.run("1 / 0")
    end
  end
end
