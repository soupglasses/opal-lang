defmodule Opal.Evaluator do
  @doc """
  Evaluator for the Opal language
  Evaluate AST produced by parser
  """
  alias Opal.Environment

  @doc """
  Evaluates an Opal program in the given environment
  """
  @spec eval(any(), Environment.t()) :: {:ok, any(), Environment.t()} | {:error, String.t()}
  def eval(ast, env) do
    try do
      {value, new_env} = do_eval(ast, env)
      {:ok, value, new_env}
    rescue
      e in RuntimeError -> {:error, e.message}
      _ -> {:error, "Evaluation error"}
    end
  end

  # Handle basic literals
  defp do_eval({:int, value}, env), do: {value, env}
  defp do_eval({:float, value}, env), do: {value, env}

  # Handle arithmetic expressions
  defp do_eval({:add, left, right}, env) do
    {left_val, env1} = do_eval(left, env)
    {right_val, env2} = do_eval(right, env1)
    {left_val + right_val, env2}
  end

  defp do_eval({:subtract, left, right}, env) do
    {left_val, env1} = do_eval(left, env)
    {right_val, env2} = do_eval(right, env1)
    {left_val - right_val, env2}
  end

  defp do_eval({:multiply, left, right}, env) do
    {left_val, env1} = do_eval(left, env)
    {right_val, env2} = do_eval(right, env1)
    {left_val * right_val, env2}
  end

  defp do_eval({:divide, left, right}, env) do
    {left_val, env1} = do_eval(left, env)
    {right_val, env2} = do_eval(right, env1)
    if right_val == 0 do
      raise "Division by zero"
    else
      {left_val / right_val, env2}
    end
  end

  #variable reference
  defp do_eval({:var, name}, env) do
    case Environment.lookup(env, name) do
      {:ok, value} -> {value, env}
      {:error, :undefined_variable} -> raise "Undefined variable: #{name}"
    end
  end

  # Variable definition
  defp do_eval({:def, name, expr}, env) do
    {value, env1} = do_eval(expr, env)
    {value, Environment.define(env1, name, value)}
  end

   # Block of expressions with a new scope
   defp do_eval({:block, exprs}, env) do
    # Create a new environment that extends the current one
    block_env = Environment.extend(env)

    # Evalaute all expressions in the block environment
    {result, final_block_env} = Enum.reduce(exprs, {nil, block_env}, fn expr, {_, acc_env} ->
      do_eval(expr, acc_env)
    end)

    # End of block, returns result with original environment
    {result, env}
  end

  # Block of expressions without a new scope
  defp do_eval({:seq, exprs}, env) do
    Enum.reduce(exprs, {nil, env}, fn expr, {_, acc_env} ->
      do_eval(expr, acc_env)
    end)
  end

  # Handle unrecognized AST nodes
  defp do_eval(unknown, _env) do
    raise "Unknown expression: #{inspect(unknown)}"
  end
end
