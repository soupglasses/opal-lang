defmodule Opal do
  @moduledoc """
  Documentation for `Opal`.
  """

  alias Opal.Lexer
  alias Opal.Parser

  def parse(code) do
    with {:ok, tokens} <- Lexer.tokenize(code) do
      Parser.parse(tokens)
    else
      err -> err
    end
  end
end
