defmodule Opal.Lexer do
  @moduledoc """
  Lexical analyzer for Opal.
  """

  @doc """
  Tokenize a string of Opal code.
  Returns {:ok, tokens} or {:error, reason}
  """
  def tokenize(code) when is_binary(code) do
    code
    |> String.to_charlist()
    |> tokenize()
  end

  def tokenize(code) when is_list(code) do
    code
    |> :opal_lexer.string()
    |> case do
      {:ok, tokens, _endpos} ->
        {:ok, tokens}

      {:error, {_line, :opal_lexer, {:user, {type, {line, col}, error}}}, _endpos} ->
        {:error, "Lexical error on line #{line}:#{col}: #{type} #{inspect(error)}"}

      {:error, {line, :opal_lexer, error}, _endpos} ->
        {:error, "Lexical error on line #{line}: #{inspect(error)}"}
    end
  end
end
