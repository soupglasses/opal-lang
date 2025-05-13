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

  # TODO: Output to CERL?
  def compile(code) do
    with {:ok, ast} <- parse(code) do
      Compiler.compile(ast)
    end
  end

  def compile(code, args) do
    with {:ok, ast} <- parse(code) do
      Compiler.compile(ast, args)
    end
  end

  def to_core(code) do
    with {:ok, ast} <- parse(code) do
      Compiler.format_core(ast)
    end
  end

  def run(code) do
    with {:ok, ast} <- parse(code) do
      Compiler.run(ast)
    end
  end
end
