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
    with {:ok, module_name, binary, _warnings} <- compile(ast),
         {:module, module} <- :code.load_binary(module_name, ~c"nopath", binary) do
      {:ok, module}
    else
      err -> err
    end
  end

  # TODO: Figure out a better interface?
  def compile(ast) do
    compile(ast, [:binary, :verbose])
  end

  def compile(ast, args) do
    :compile.forms(generate_core(ast), [:from_core, :return] ++ args)
  end

  def format_core(ast) do
    generate_core(ast)
    |> :core_pp.format()
    |> :erlang.iolist_to_binary()
  end

  def generate_core(ast) do
    {core_expr, _env} = generate_core(ast, %{})
    modulename = :"Opal.Script"
    # env -> {:funcs -> ..., :vars -> ..., :module_name -> ''}

    # Entrypoint
    c_module(
      c_atom(modulename), # name
      # TODO: add c_fname(:module_info, 0), c_fname(:module_info, 1)] to exports.
      [c_fname(:run, 0)], # exports [V1, ...] where V is fname var.
      [], # attributes: [{K1, T1}, ...] where K is atom, T is constant.
      [{c_fname(:run, 0), c_fun([], core_expr)}] # definitions: [{V1, F1}, ...] where V is fname var, F is fun type.
    )
  end

  defp generate_core([stmt | []], env) do
    generate_core(stmt, env)
  end

  defp generate_core([stmt | stmts], env0) do
    with {stmt_eval, env1} = generate_core(stmt, env0),
         {stmts_eval, env2} = generate_core(stmts, env1) do
      {c_seq(stmt_eval, stmts_eval), env2}
    end
  end

  # TODO: Assumes c_var as identifier. Needs :c_literal case when `1 = 1` is done.
  defp generate_core({:match, identifier, argument, body}, env0) do
    with {id_eval, env1} = generate_core(identifier, env0),
         {arg_eval, env2} = generate_core(argument, env1),
         {body_eval, env3} = generate_core(body, env2) do
      {c_let([id_eval], arg_eval, body_eval), env3}
    end
  end

  defp generate_core({:var, value}, env), do: {c_var(value), env}
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
