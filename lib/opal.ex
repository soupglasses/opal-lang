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
    else
      err -> err
    end
  end

  def run(code) do
    with {:ok, tokens} <- Lexer.tokenize(code),
         {:ok, ast} <- Parser.parse(tokens) do
      Compiler.run(ast)
    else
      err -> err
    end
  end
end
