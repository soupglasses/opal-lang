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
        validate_tokens(tokens)

      {:error, {_line, :opal_lexer, {:user, {type, {line, col}, error}}}, _endpos} ->
        {:error, "Lexical error on line #{line}:#{col}: #{type} #{inspect(error)}"}

      {:error, {line, :opal_lexer, error}, _endpos} ->
        {:error, "Lexical error on line #{line}: #{inspect(error)}"}
    end
  end

  defp validate_tokens([]), do: {:ok, []}

  defp validate_tokens([{:int, {line, col}, 0}, {:int, _, _} | _rest]) do
    {:error, {:invalid_integer, {line, col}, ~c"0"}}
  end

  defp validate_tokens([{:int, {line, col}, digit}, {:identifier, _, _} | _rest]) do
    {:error, {:invalid_identifier, {line, col}, Integer.to_charlist(digit)}}
  end

  defp validate_tokens([token | rest]) do
    case validate_tokens(rest) do
      {:ok, verified_rest} -> {:ok, [token | verified_rest]}
      error -> error
    end
  end
end
