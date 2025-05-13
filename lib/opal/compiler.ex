defmodule Opal.Compiler do
  @moduledoc """
  Compiler to Core Erlang for Opal.
  """

  import :cerl

  def generate_core(ast) do
    {core_expr, _env} = generate_core(ast, %{})
    modulename = :"Opal.Script"
    # env -> {:funcs -> ..., :vars -> ..., :module_name -> ''}

    # Entrypoint
    c_module(
      # name
      c_atom(modulename),
      # TODO: add c_fname(:module_info, 0), c_fname(:module_info, 1)] to exports.
      # exports [V1, ...] where V is fname var.
      [c_fname(:run, 0)],
      # attributes: [{K1, T1}, ...] where K is atom, T is constant.
      [],
      # definitions: [{V1, F1}, ...] where V is fname var, F is fun type.
      [{c_fname(:run, 0), c_fun([], core_expr)}]
    )
  end

  defp generate_core([stmt | []], env) do
    generate_core(stmt, env)
  end

  defp generate_core([stmt | stmts], env0) do
    with {stmt_eval, env1} = generate_core(stmt, env0),
         {stmts_eval, env2} = generate_core(stmts, env1) do
      # TODO: This breaks assignment!
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

  defp generate_core({:var, pos, value}, env), do: {ann_c_var([pos], value), env}
  defp generate_core({:int, pos, value}, env), do: {ann_c_int([pos], value), env}
  defp generate_core({:float, pos, value}, env), do: {ann_c_float([pos], value), env}

  # defp generate_core({:fn, name, args, body}, env) do
  #  arity = List.length(args)
  #  env = %{exports: MapSet.new()}
  #  Map.update!(x, :exports, fn exports -> MapSet.put(exports, :cerl.c_fname(name, arity)) end)
  #  Map.update(x, :exports, MapSet.new(), fn exports -> MapSet.put(exports, c_fname(name, arity)) end)
  #  Map.update(x, :funcs, %{}, fn funcs -> {c_fname(name, arity), %{case}} end)
  # end

  # TODO: Flatten call exprs with anonymous variables.

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
