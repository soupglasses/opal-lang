defmodule Opal.Compiler do
  @moduledoc """
  Compiler to Core Erlang for Opal.
  """

  import :cerl

  def run(ast) do
    {:ok, module} = compile_and_load(ast)
    module.run()
  end

  def compile_and_load(ast) do
    with {:ok, :"Opal.test", binary} <- compile(ast),
         {:module, module} <- :code.load_binary(:"Opal.test", ~c"nopath", binary) do
      {:ok, module}
    else
      err -> err
    end
  end

  # TODO: Figure out a better interface?
  def compile(ast) do
    # TODO: What does :return do? Adds an empty array at the end?
    # TODO: Wrap interface in case?
    :compile.forms(generate_core(ast), [:from_core, :binary])
  end

  def format_core(ast) do
    generate_core(ast)
    |> :core_pp.format()
    |> :erlang.iolist_to_binary()
  end

  def generate_core(ast) do
    {core_expr, _env} = generate_core(ast, [])
    modulename = :"Opal.test"
    # env -> {:funcs -> ..., :vars -> ..., :module_name -> ''}

    # Entrypoint
    c_module(
      c_atom(modulename),
      # TODO: add c_fname(:module_info, 0), c_fname(:module_info, 1)].
      [c_fname(:run, 0)],
      [],
      [{c_fname(:run, 0), c_fun([], core_expr)}]
    )
  end

  defp generate_core({:int, value}, env), do: {c_int(value), env}
  defp generate_core({:float, value}, env), do: {c_float(value), env}

  defp generate_core({:add, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {c_call(
         c_atom(:erlang),
         c_atom(:+),
         [left_expr, right_expr]
       ), env2}
    end
  end

  defp generate_core({:subtract, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {c_call(
         c_atom(:erlang),
         c_atom(:-),
         [left_expr, right_expr]
       ), env2}
    end
  end

  defp generate_core({:multiply, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {c_call(
         c_atom(:erlang),
         c_atom(:*),
         [left_expr, right_expr]
       ), env2}
    end
  end

  # TODO: Can raise '(ArithmeticError) bad argument' on division by 0.
  defp generate_core({:divide, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {c_call(
         c_atom(:erlang),
         c_atom(:/),
         [left_expr, right_expr]
       ), env2}
    end
  end
end
