defmodule Opal.EvaluatorTest do
  use ExUnit.Case
  alias Opal.Environment
  alias Opal.Evaluator

  test "evaluate integer literal" do
    ast = {:int, 42}
    env = Environment.new()
    assert {:ok, 42, _} = Evaluator.eval(ast, env)
  end

  test "evaluate float literal" do
    ast = {:float, 3.14}
    env = Environment.new()
    assert {:ok, 3.14, _} = Evaluator.eval(ast, env)
  end

  test "evaluate basic arithmetic" do
    add_ast = {:add, {:int, 2}, {:int, 3}}
    subtract_ast = {:subtract, {:int, 10}, {:int, 4}}
    multiply_ast = {:multiply, {:int, 5}, {:int, 6}}
    divide_ast = {:divide, {:int, 20}, {:int, 5}}
    env = Environment.new()
    assert {:ok, 5, _} = Evaluator.eval(add_ast, env)
    assert {:ok, 6, _} = Evaluator.eval(subtract_ast, env)
    assert {:ok, 30, _} = Evaluator.eval(multiply_ast, env)
    assert {:ok, 4.0, _} = Evaluator.eval(divide_ast, env)
  end

  test "division by zero" do
    ast = {:divide, {:int, 10}, {:int, 0}}
    env = Environment.new()
    assert {:error, "Division by zero"} = Evaluator.eval(ast, env)
  end

  test "evaluate variable definition and reference" do
    # let x = 10;
    def_ast = {:def, :x, {:int, 10}}
    # x
    var_ast = {:var, :x}
    env = Environment.new()
    # Evaluate the definition
    {:ok, 10, env} = Evaluator.eval(def_ast, env)
    # Evaluate the reference
    assert {:ok, 10, _} = Evaluator.eval(var_ast, env)
  end

  test "evaluate undefined variable" do
    var_ast = {:var, :x}
    env = Environment.new()
    assert {:error, "Undefined variable: x"} = Evaluator.eval(var_ast, env)
  end


  test "evaluate complex expression" do
    # let x = 10;
    # let y = 5;
    # x * y + 2;
    block_ast = {:block, [
      {:def, :x, {:int, 10}},
      {:def, :y, {:int, 5}},
      {:add, {:multiply, {:var, :x}, {:var, :y}}, {:int, 2}}
    ]}
    env = Environment.new()
    assert {:ok, 52, env} = Evaluator.eval(block_ast, env)
    assert {:ok, 10} = Environment.lookup(env, :x)
    assert {:ok, 5} = Environment.lookup(env, :y)
  end

  test "evaluate nested scope" do
    block_ast = {:block, [
      {:def, :x, {:int, 10}},
      {:block, [
        {:def, :x, {:int, 20}},
        {:var, :x}
      ]},
      {:var, :x}
    ]}
    env = Environment.new()
    # test requires implementing nested scopes in the evaluator
    # For now, it should shadow the outer x with the inner x
    assert {:ok, 10, _} = Evaluator.eval(block_ast, env)
  end
end
