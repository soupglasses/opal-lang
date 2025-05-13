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
    with {:ok, ast} <- parse(code) do
      Compiler.generate_core(ast)
      |> :compile.forms([:from_core, :verbose, :return] ++ opts)
    end
  end

  def to_core(code) do
    with {:ok, ast} <- parse(code) do
      Compiler.generate_core(ast)
      |> :core_pp.format()
      |> :erlang.iolist_to_binary()
    end
  end

  # TODO: Use core_eval?
  def run(code) do
    with {:ok, module_name, binary, _warnings} <- compile(code),
         {:module, module} <- :code.load_binary(module_name, ~c"nopath", binary) do
      module.run()
    end
  end
end
