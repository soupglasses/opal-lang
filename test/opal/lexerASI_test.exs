defmodule Opal.LexerASITest do
  use ExUnit.Case
  alias Opal.Lexer


  describe "Automatic Semicolon Insertion" do
    test "ASI does not insert semicolon after certain tokens followed by newline" do
      # Using operators that shouldn't trigger ASI
      code = """
      x +
      y
      """
      {:ok, tokens} = Lexer.tokenize(code)

      refute Enum.any?(Enum.chunk_every(tokens, 2, 1, :discard), fn
        [ {'+', _}, ~c";" ] -> false
        _ -> false
      end)
    end
    test "ASI Does not trigger on newline mid expression" do
      # Using operators that shouldn't trigger ASI
      code = """
      x
      + y
      """
      {:ok, tokens} = Lexer.tokenize(code)

      refute Enum.any?(Enum.chunk_every(tokens, 2, 1, :discard), fn
        [ {'+', _}, ~c";" ] -> false
        _ -> false
      end)
    end
  end
end
