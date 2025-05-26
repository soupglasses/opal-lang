defmodule Opal.Compiler do
  @moduledoc """
  Compiler to Core Erlang for Opal.
  """

  import :cerl

  def compile(ast) do
    # TODO: Multiple modules in a single AST?
    # TODO: Filenames?
    case ast do
      {:module, loc, {{:module_id, _, name}, blocks}} -> generate_module(loc, {name, blocks})
      blocks when is_list(blocks) -> generate_module(nil, {:"Opal.Script", blocks})
    end
  end

  def init_env() do
    %{
      fun_names: [],
      fun_clauses: %{},
      local_var_count: 0
    }
  end

  def generate_module(loc, {module_name, blocks_ast}) do
    # Adds functions to env, append exprs together.
    {exprs_ast, env1} =
      Enum.reduce(blocks_ast, {[], init_env()}, fn
        {:function, loc, {{:var, _, name}, args, body}}, {exprs, env_acc} ->
          env_new = add_fun_clause(loc, {name, args, body}, env_acc)
          {exprs, env_new}

        # Because statements -> [...]
        expr, {exprs, env_acc} ->
          {exprs ++ expr, env_acc}
      end)

    # Create last main/1 to wrap possibly loose exprs.
    env =
      if exprs_ast != [] do
        # HACK: Reshape :c_var back into AST :var for `add_fun_clause`.
        {{:c_var, ann, name}, env2} = new_c_var(env1)
        add_fun_clause(nil, {:main, {:patterns, [{:var, ann, name}]}, exprs_ast}, env2)
      else
        env1
      end

    # TODO: add c_fname(:module_info, 0), c_fname(:module_info, 1)] to exports.
    exports = Enum.map(env[:fun_names], fn {name, arity} -> c_fname(name, arity) end)

    definitions =
      Enum.map(env[:fun_names], fn {name, arity} ->
        clauses = Map.get(env[:fun_clauses], {name, arity}, [])
        # Define variable arguments for the top level anonymous function.
        # TODO: local_var_count possibly incorrect (argument reuse across functions)
        {anon_args, env_z} = new_c_vars(arity, env)
        {function_clause, _} = default_clause({:function_clause, arity}, env_z)

        {c_fname(name, arity),
         c_fun(
           anon_args,
           c_case(
             c_values(anon_args),
             clauses ++ [function_clause]
           )
         )}
      end)

    ann_c_module(
      ann(loc),
      c_atom(module_name),
      # exports: [V1, ...] where V is fname var.
      exports,
      # attributes: [{K1, T1}, ...] where K is atom, T is constant. like 'file: name'
      [],
      # definitions: [{V1, F1}, ...] where V is fname var, F is fun type.
      definitions
    )
  end

  def add_fun_clause(loc, {name, {:patterns, arg_list} = args, body}, env0) do
    arity = length(arg_list)

    # Keep track of fun names, required to keep user ordering.
    env1 =
      if {name, arity} not in env0[:fun_names] do
        Map.update(env0, :fun_names, [{name, arity}], fn fun_names ->
          fun_names ++ [{name, arity}]
        end)
      else
        env0
      end

    {args_expr, env2} = generate_core(args, env1)
    {body_expr, env3} = generate_core(body, env2)

    clause_expr =
      ann_c_clause(
        ann(loc),
        args_expr,
        body_expr
      )

    # Append clause to env[fun_clauses][{name, arity}]
    env4 =
      Map.update(env3, :fun_clauses, %{}, fn fun_clauses ->
        Map.update(fun_clauses, {name, arity}, [clause_expr], fn clauses ->
          clauses ++ [clause_expr]
        end)
      end)

    env4
  end

  # Returns {c_var, env}
  def new_c_var(env0) do
    env1 = Map.update(env0, :local_var_count, 0, fn count -> count + 1 end)

    {ann_c_var(ann(:compiler_generated), env1.local_var_count), env1}
  end

  # returns {[c_var0, ..., c_varN], env}
  def new_c_vars(count, env0) do
    if count == 0 do
      {[], env0}
    else
      Enum.reduce(1..count, {[], env0}, fn _, {vars, env_acc} ->
        {var, env_next} = new_c_var(env_acc)
        {vars ++ [var], env_next}
      end)
    end
  end

  # Cerl requires all cases to have a fall-through clause which always matches.
  def default_clause({kind, arity}, env0) do
    {match_fail_args, env1} = new_c_vars(arity, env0)

    {ann_c_clause(
       ann(:compiler_generated),
       match_fail_args,
       c_primop(
         c_atom(:match_fail),
         [c_tuple([c_atom(kind)] ++ match_fail_args)]
       )
     ), env1}
  end

  defp generate_core([{{:=, loc}, lhs, rhs} | body], env0) do
    with {lhs_eval, env1} = generate_core(lhs, env0),
         {rhs_eval, env2} = generate_core(rhs, env1) do
      # If we are the last statement, use the right hand side as our return.
      {body_eval, env3} =
        case body do
          [] -> {rhs_eval, env2}
          _ -> generate_core(body, env2)
        end

      # WARN: This assumes full literals lhs, or a single assignment.
      if Enum.all?(lhs_eval, &is_literal/1) do
        {badmatch_clause, env4} = default_clause({:badmatch, length(lhs_eval)}, env3)

        {ann_c_case(ann(loc), rhs_eval, [c_clause(lhs_eval, body_eval), badmatch_clause]), env4}
      else
        {ann_c_let(ann(loc), lhs_eval, rhs_eval, body_eval), env3}
      end
    end
  end

  defp generate_core({:patterns, patterns}, env0) do
    {patterns_eval, env1} =
      Enum.reduce(patterns, {[], env0}, fn
        pattern, {patterns, env_acc} ->
          with {pattern_eval, env_new} <- generate_core(pattern, env_acc) do
            {patterns ++ [pattern_eval], env_new}
          end
      end)

    {patterns_eval, env1}
  end

  # For empty patterns and args.
  defp generate_core([], env) do
    {[], env}
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

  # TODO: Missing module_id and Opal function calls.
  # TODO: Missing char.
  # TODO: Missing list.
  defp generate_core({:var, pos, value}, env), do: {ann_c_var(ann(pos), value), env}
  defp generate_core({:int, pos, value}, env), do: {ann_c_int(ann(pos), value), env}
  defp generate_core({:float, pos, value}, env), do: {ann_c_float(ann(pos), value), env}
  defp generate_core({:bool, pos, value}, env), do: {{:c_literal, ann(pos), value}, env}
  defp generate_core({:atom, pos, value}, env), do: {ann_c_atom(ann(pos), value), env}
  defp generate_core({:string, pos, value}, env), do: {ann_c_string(ann(pos), value), env}
  defp generate_core({:char, pos, value}, env), do: {ann_c_char(ann(pos), value), env}

  # Optimization to use `is_literal_term()` for certain args when `let _n = arg` is redundant.
  defp generate_core({:apply, loc, {{:var, name_pos, name}, {:args, args}}}, env0) do
    arity = length(args)
    {c_vars, env1} = new_c_vars(arity, env0)

    {apply_eval, env2} =
      {ann_c_apply(
         ann(loc),
         ann_c_fname(ann(name_pos), name, arity),
         c_vars
       ), env1}

    {body_eval, env3} =
      Enum.reduce(Enum.zip(Enum.reverse(args), c_vars), {apply_eval, env2}, fn
        {arg, c_var}, {apply_eval, env_acc} ->
          with {arg_eval, env_new} <- generate_core(arg, env_acc) do
            {c_let([c_var], arg_eval, apply_eval), env_new}
          end
      end)

    {body_eval, env3}
  end

  # TODO: Deduplicate between :apply and :call
  defp generate_core({:call, loc, {module, {:var, name_pos, name}, {:args, args}}}, env0) do
    arity = length(args)
    {c_vars, env1} = new_c_vars(arity, env0)
    {module_expr, env2} = generate_core(module, env1)

    {apply_eval, env3} =
      {ann_c_call(
         ann(loc),
         module_expr,
         ann_c_atom(ann(name_pos), name),
         c_vars
       ), env2}

    {body_eval, env4} =
      Enum.reduce(Enum.zip(Enum.reverse(args), c_vars), {apply_eval, env3}, fn
        {arg, c_var}, {apply_eval, env_acc} ->
          with {arg_eval, env_new} <- generate_core(arg, env_acc) do
            {c_let([c_var], arg_eval, apply_eval), env_new}
          end
      end)

    {body_eval, env4}
  end

  # TODO: Missing import statement functionality.

  # TODO: Flatten call exprs with anonymous variables?

  defp generate_core({{:+, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:+),
         [left_expr, right_expr]
       ), env2}
    end
  end

  defp generate_core({{:-, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:-),
         [left_expr, right_expr]
       ), env2}
    end
  end

  defp generate_core({{:*, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:*),
         [left_expr, right_expr]
       ), env2}
    end
  end

  # TODO: Can raise '(ArithmeticError) bad argument' on division by 0. Language has currently no native way to recover from this.
  defp generate_core({{:/, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:/),
         [left_expr, right_expr]
       ), env2}
    end
  end

  # TODO: Rewrite this to use Integer.pow() or similar. Returns a float currently.
  defp generate_core({{:^, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:math),
         c_atom(:pow),
         [left_expr, right_expr]
       ), env2}
    end
  end

  defp generate_core({{:%, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:rem),
         [left_expr, right_expr]
       ), env2}
    end
  end

  defp generate_core({{:==, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:==),
         [left_expr, right_expr]
       ), env2}
    end
  end

  defp generate_core({{:!=, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:"/="),
         [left_expr, right_expr]
       ), env2}
    end
  end

  defp generate_core({{:<=, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:"=<"),
         [left_expr, right_expr]
       ), env2}
    end
  end

  defp generate_core({{:<, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:<),
         [left_expr, right_expr]
       ), env2}
    end
  end

  defp generate_core({{:>=, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:>=),
         [left_expr, right_expr]
       ), env2}
    end
  end

  defp generate_core({{:>, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:>),
         [left_expr, right_expr]
       ), env2}
    end
  end

  defp generate_core({{:-, loc}, body}, env) do
    with {body_expr, env1} = generate_core(body, env) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:-),
         [body_expr]
       ), env1}
    end
  end

  defp generate_core({{:not, loc}, body}, env) do
    with {body_expr, env1} = generate_core(body, env) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:not),
         [body_expr]
       ), env1}
    end
  end

  defp generate_core({{:and, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:and),
         [left_expr, right_expr]
       ), env2}
    end
  end

  defp generate_core({{:or, loc}, left, right}, env) do
    with {left_expr, env1} = generate_core(left, env),
         {right_expr, env2} = generate_core(right, env1) do
      {ann_c_call(
         ann(loc),
         c_atom(:erlang),
         c_atom(:or),
         [left_expr, right_expr]
       ), env2}
    end
  end

  # Helper functions
  def ann(nil), do: []
  def ann({}), do: []
  def ann(list) when is_list(list), do: Enum.flat_map(list, &ann/1)
  def ann(thing), do: [thing]
end
