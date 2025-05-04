defmodule Opal.Evaluator do
  @moduledoc """
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

  # Variable reference
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
    # Evaluate all expressions in the block environment
    {result, _final_block_env} = Enum.reduce(exprs, {nil, block_env}, fn expr, {_, acc_env} ->
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

  # Function definition
  defp do_eval({:fn_def, name, params, body}, env) do
    fn_value = {:function, params, body, env}
    {fn_value, Environment.define(env, name, fn_value)}
  end

  # Yield to block
  defp do_eval({:yield, args}, env) do
    case Environment.lookup(env, :__block__) do
      {:ok, _block_fn} ->
        # Call the block with the provided arguments
        do_eval({:call, :__block__, args}, env)

      {:error, :undefined_variable} ->
        raise "No block given (yield used outside block context)"
    end
  end

  # Function application/call
  defp do_eval({:call, name, args}, env) do
    case Environment.lookup(env, name) do
      {:ok, {:function, params, body, closure_env}} ->
        # Evaluate all arguments in the current environment
        {arg_values, new_env} =
          Enum.reduce(args, {[], env}, fn arg, {values, e} ->
            {val, e1} = do_eval(arg, e)
            {values ++ [val], e1}
          end)

        # Create function call environment with arguments bound to parameters
        call_env =
          Enum.zip(params, arg_values)
          |> Enum.reduce(Environment.extend(closure_env), fn {param, value}, acc ->
            Environment.define(acc, param, value)
          end)

        # Evaluate function body in the call environment
        {result, _} = do_eval(body, call_env)

        # Return result with original environment (ignore function's local env)
        {result, new_env}

      {:ok, _non_function} ->
        raise "#{name} is not a function"

      {:error, :undefined_variable} ->
        raise "Undefined function: #{name}"
    end
  end

  # Function call with block
  defp do_eval({:call_with_block, name, args, block}, env) do
    case Environment.lookup(env, name) do
      {:ok, {:function, params, body, closure_env}} ->
        # Evaluate all arguments in the current environment
        {arg_values, new_env} =
          Enum.reduce(args, {[], env}, fn arg, {values, e} ->
            {val, e1} = do_eval(arg, e)
            {values ++ [val], e1}
          end)

        # Evaluate block to a function value
        {block_fn, _} = do_eval({:fn_def, :__block__, [], block}, env)

        # Create function call environment with arguments bound to parameters
        # and add the block as a special __block__ value
        call_env =
          Enum.zip(params, arg_values)
          |> Enum.reduce(Environment.extend(closure_env), fn {param, value}, acc ->
            Environment.define(acc, param, value)
          end)
          |> Environment.define(:__block__, block_fn)

        # Evaluate function body in the call environment
        {result, _} = do_eval(body, call_env)

        # Return result with original environment (ignore function's local env)
        {result, new_env}

      {:ok, _non_function} ->
        raise "#{name} is not a function"

      {:error, :undefined_variable} ->
        raise "Undefined function: #{name}"
    end
  end

  # Tuple type
  defp do_eval({:tuple, elements}, env) do
    {values, new_env} =
      Enum.reduce(elements, {[], env}, fn element, {values, e} ->
        {val, e1} = do_eval(element, e)
        {values ++ [val], e1}
      end)

    {List.to_tuple(values), new_env}
  end

  # Result types
  defp do_eval({:ok_result, value}, env) do
    {val, new_env} = do_eval(value, env)
    {{:ok, val}, new_env}
  end

  defp do_eval({:error_result, value}, env) do
    {val, new_env} = do_eval(value, env)
    {{:error, val}, new_env}
  end

  # Pipe operator (|>)
  defp do_eval({:pipe, left, right}, env) do
    {left_val, env1} = do_eval(left, env)

    case right do
      {:var, fn_name} ->
        # Simple function reference
        do_eval({:call, fn_name, [left_val]}, env1)

      {:call, fn_name, args} ->
        # Function call with args, insert left_val as first arg
        do_eval({:call, fn_name, [left_val | args]}, env1)

      _ ->
        # Otherwise assume it's a function expression
        {fn_val, env2} = do_eval(right, env1)
        case fn_val do
          {:function, params, body, closure_env} ->
            # Call the function with left_val as argument
            call_env = Environment.define(Environment.extend(closure_env),
                                         hd(params), left_val)
            {result, _} = do_eval(body, call_env)
            {result, env2}
          _ ->
            raise "Right side of |> must be a function"
        end
    end
  end

  # Bind operator (>>=)
  defp do_eval({:bind, left, right}, env) do
    {left_val, env1} = do_eval(left, env)

    case left_val do
      {:ok, value} ->
        # For success case, extract value and pass to right side
        case right do
          {:var, fn_name} ->
            do_eval({:call, fn_name, [value]}, env1)

          {:call, fn_name, args} ->
            do_eval({:call, fn_name, [value | args]}, env1)

          _ ->
            {fn_val, env2} = do_eval(right, env1)
            case fn_val do
              {:function, params, body, closure_env} ->
                call_env = Environment.define(Environment.extend(closure_env),
                                            hd(params), value)
                {result, _} = do_eval(body, call_env)
                {result, env2}
              _ ->
                raise "Right side of >>= must be a function"
            end
        end

      {:error, _} = error ->
        # For error case, short-circuit and just pass through the error
        {error, env1}

      _ ->
        raise "Left side of >>= must be a Result type (Ok or Error)"
    end
  end

  # Type definition
  defp do_eval({:type_def, name, type_expr}, env) do
    {type_def, env1} = do_eval(type_expr, env)
    {type_def, Environment.define(env1, name, {:type, type_def})}
  end

  # Type expressions
  defp do_eval({:type_ref, name}, env) do
    case Environment.lookup(env, name) do
      {:ok, {:type, type_def}} -> {type_def, env}
      {:ok, _} -> raise "#{name} is not a type"
      {:error, :undefined_variable} -> raise "Undefined type: #{name}"
    end
  end

  defp do_eval({:ok_type, type_name}, env) do
    {{:ok_type, type_name}, env}
  end

  defp do_eval({:error_type, type_name}, env) do
    {{:error_type, type_name}, env}
  end

  defp do_eval({:union_type, left, right}, env) do
    {left_type, env1} = do_eval(left, env)
    {right_type, env2} = do_eval(right, env1)
    {{:union, left_type, right_type}, env2}
  end

  # Conditional if/else
  defp do_eval({:if_expr, condition, then_block, else_block}, env) do
    {condition_val, env1} = do_eval(condition, env)

    if condition_val do
      do_eval(then_block, env1)
    else
      do_eval(else_block, env1)
    end
  end

  # Handle unrecognized AST nodes
  defp do_eval(unknown, _env) do
    raise "Unknown expression: #{inspect(unknown)}"
  end
end
