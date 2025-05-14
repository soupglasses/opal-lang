defmodule Opal.Parser do
  @moduledoc """
  LALR Parser for Opal.
  """
  @doc """
  Parse tokens into an abstract syntax tree.
  Returns {:ok, ast} or {:error, reason}
  """
  def parse(tokens) when is_list(tokens) do
    try do
      case :opal_parser.parse(tokens) do
        {:ok, ast} ->
          {:ok, ast}
        {:error, {pos, :opal_parser, error}} ->
          error_message = format_error_position(pos, error)
          {:error, error_message}
      end
    rescue
      e in Protocol.UndefinedError ->
        # Fall back to a safe error representation when String.Chars fails
        {:error, "Parse error: Unable to format error position (#{inspect(e.value)})"}
      e ->
        {:error, "Unexpected error during parsing: #{inspect(e)}"}
    end
  end

  # Helper function to safely format error positions without String.Chars protocol errors
  defp format_error_position(pos, error) do
    position_str = case pos do
      {line, col} when is_integer(line) and is_integer(col) ->
        "#{line}:#{col}"
      line when is_integer(line) ->
        "#{line}"
      _ ->
        "#{inspect(pos)}"
    end

    "Parse error at position #{position_str}: #{inspect(error)}"
  end
end
