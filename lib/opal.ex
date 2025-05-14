defmodule Opal do
  @moduledoc """
  Documentation for `Opal`.
  """
  alias Opal.Lexer
  alias Opal.Parser
  alias Opal.Compiler

  def tokenize(code) do
    Lexer.tokenize(code)
  end

  def parse(code) do
    with {:ok, tokens} <- Lexer.tokenize(code) do
      Parser.parse(tokens)
    end
  end

  def compile(code), do: compile(code, [])
  def compile(code, opts) do
    try do
      with {:ok, ast} <- parse(code) do
        Compiler.generate_core(ast)
        |> :compile.forms([:from_core, :verbose, :return] ++ opts)
      end
    rescue
      e ->
        {:error, "Compilation error: #{inspect(e)}"}
    end
  end

  def to_core(code) do
    try do
      with {:ok, ast} <- parse(code) do
        Compiler.generate_core(ast)
        |> :core_pp.format()
        |> :erlang.iolist_to_binary()
      end
    rescue
      e ->
        {:error, "Error generating core format: #{inspect(e)}"}
    end
  end

  # TODO: Use core_eval?
  def run(code) do
    try do
      with {:ok, module_name, binary, _warnings} <- compile(code),
           {:module, module} <- :code.load_binary(module_name, ~c"nopath", binary) do
        module.run()
      else
        {:error, reason} when is_binary(reason) ->
          IO.puts("Error: #{reason}")
          nil
        {:error, reason} ->
          IO.puts("Error: #{inspect(reason)}")
          nil
        error ->
          IO.puts("Unexpected error: #{inspect(error)}")
          nil
      end
    rescue
      e ->
        IO.puts("Runtime error: #{inspect(e)}")
        nil
    end
  end
end
