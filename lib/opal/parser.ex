defmodule Opal.Parser do
  @moduledoc """
  LALR Parser for Opal.
  """

  @doc """
  Parse tokens into an abstract syntax tree.
  Returns {:ok, ast} or {:error, reason}
  """
  def parse(tokens) when is_list(tokens) do
    case :opal_parser.parse(tokens) do
      {:ok, ast} ->
        {:ok, ast}

      error ->
        error
        # {:error, {{line, col}, :opal_parser, error}} ->
        #  {:error, "Parse error on line #{line}:#{col}: #{inspect(error)}"}
    end
  end
end
