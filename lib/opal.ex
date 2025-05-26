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
      Compiler.compile(ast)
      |> tap(fn line -> if :verbose in opts, do: IO.inspect(line) end)
      |> :compile.forms([:from_core, :verbose, :report, :return] ++ opts)
    end
  end

  def to_core(code), do: to_core(code, [])

  def to_core(code, opts) do
    with {:ok, ast} <- parse(code) do
      Compiler.compile(ast)
      |> tap(fn line -> if :verbose in opts, do: IO.inspect(line) end)
      |> :core_pp.format()
      |> :erlang.iolist_to_binary()
    end
  end

  def load(code) do
    with {:ok, module_name, binary, _warnings} <- compile(code) do
      :code.load_binary(module_name, ~c"nopath", binary)
    end
  end

  # TODO: Use core_eval?
  def run(code) do
    with {:module, module} <- load(code) do
      module.main(~c"")
    end
  end
end
