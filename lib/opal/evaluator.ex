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
end
