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
        tokens
        |> validate_tokens()
        |> case do
          {:ok, validated_tokens} ->
            {:ok, insert_semicolons(validated_tokens)}
          error ->
            error
        end

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

  # Second pass: semicolon insertion
  defp insert_semicolons(tokens) do
    tokens
    |> process_newlines([])
    |> Enum.reverse()
  end

  defp process_newlines([{:newline, loc}, next_token | rest], [{prev_type, _} | _] = acc) do
    case keep_newline(prev_type, get_token_type(next_token)) do
      :insert_semicolon ->
        process_newlines([next_token | rest], [{:';', loc} | acc])
      :drop ->
        process_newlines([next_token | rest], acc)
    end
  end

  defp process_newlines([{:newline, loc}, next_token | rest], [{prev_type, _, _} | _] = acc) do
    case keep_newline(prev_type, get_token_type(next_token)) do
      :insert_semicolon ->
        process_newlines([next_token | rest], [{:';', loc} | acc])
      :drop ->
        process_newlines([next_token | rest], acc)
    end
  end


  defp process_newlines([{:newline, _} | rest], [] = acc) do
    process_newlines(rest, acc)
  end

  # Non-newline tokens - just accumulate
  defp process_newlines([token | rest], acc) do
    process_newlines(rest, [token | acc])
  end

  defp process_newlines([], acc), do: acc


  defp get_token_type({type, _}), do: type
  defp get_token_type({type, _, _}), do: type

  # Declarative rules for newline handling
  # Insert semicolon after identifier/closing paren, unless next token is binary operator
  defp keep_newline(:identifier, next_type) when next_type in [:'+', :'-', :'*', :'/'] do
    :drop
  end

  defp keep_newline(:')', next_type) when next_type in [:'+', :'-', :'*', :'/'] do
    :drop
  end

  defp keep_newline(:identifier, _), do: :insert_semicolon
  defp keep_newline(:')', _), do: :insert_semicolon


  defp keep_newline(_, _), do: :drop
end
