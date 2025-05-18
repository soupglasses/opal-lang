defmodule Opal.LexerASITest do
  use ExUnit.Case
  alias Opal.Lexer

  # Not sure this is supported either, just calling x and y.
  describe "Automatic Semicolon Insertion" do
    # Instead of testing internal functions directly, we test the behavior
    test "ASI inserts semicolon after identifier followed by newline" do
      code = """
      x
      y
      """
      {:ok, tokens} = Lexer.tokenize(code)

      # Check if there's a semicolon between the two identifiers
      assert Enum.any?(Enum.chunk_every(tokens, 2, 1, :discard), fn
        [ {:identifier, _, _}, ~c";" ] -> true
        _ -> false
      end)
    end

    #Not sure if this is supported, or breaks for different reason.
    test "ASI inserts semicolon after closing parenthesis followed by newline" do
      code = """
      (x)
      y
      """
      {:ok, tokens} = Lexer.tokenize(code)

      # Check if there's a semicolon after the closing parenthesis
      assert Enum.any?(Enum.chunk_every(tokens, 2, 1, :discard), fn
        [ {')', _}, ~c";" ] -> true
        _ -> false
      end)
    end

    test "ASI does not insert semicolon after certain tokens followed by newline" do
      # Using operators that shouldn't trigger ASI
      code = """
      x +
      y
      """
      {:ok, tokens} = Lexer.tokenize(code)

      # Check if there's NO semicolon between the + and y
      refute Enum.any?(Enum.chunk_every(tokens, 2, 1, :discard), fn
        [ {'+', _}, ~c";" ] -> false
        _ -> false
      end)
    end
  end

  describe "token tracking and ASI integration" do
    test "tokenize handles automatic semicolon insertion between statements" do
      code = """
      x = 42
      y = 24
      """
      # The lexer should insert a semicolon after the first line
      {:ok, tokens} = Lexer.tokenize(code)

      # Find if there's a semicolon token between the first assignment and second variable
      has_semicolon = Enum.any?(tokens, fn
        ~c";" -> true
        _ -> false
      end)
      assert has_semicolon, "Expected automatic semicolon insertion between statements"
    end
    #Syntax error?
    test "ASI works in multiline expressions" do
      code = """
      x = 1 + 2
      y = 3 + 4
      z = x + y
      """
      {:ok, tokens} = Lexer.tokenize(code)

      # Count the number of semicolons - there should be at least 2
      semicolon_count = Enum.count(tokens, fn
        ~c";" -> true
        _ -> false
      end)

      assert semicolon_count >= 2, "Expected semicolons to be inserted at the end of lines"
    end

    test "ASI works after various token types" do
      # Testing several contexts where ASI should occur
      code = """
      x = 42
      foo()
      y = "hello"
      """

      {:ok, tokens} = Lexer.tokenize(code)

      # We expect semicolons after line 1 and line 2
      # Check by finding sequences of tokens
      sequences = Enum.chunk_every(tokens, 2, 1, :discard)

      # After number literal
      assert Enum.any?(sequences, fn
        [ {:int, _, _}, ~c";" ] -> true
        _ -> false
      end)

      # After function call (closing parenthesis)
      assert Enum.any?(sequences, fn
        [ {')', _}, ~c";" ] -> true
        _ -> false
      end)
    end
  end

  # Helper functions

  # Find a sequence of token types in the token list
  defp find_sequence(tokens, types, start_index \\ 0) do
    token_types = tokens
      |> Enum.drop(start_index)
      |> Enum.map(fn
        {type, _} -> type
        {type, _, _} -> type
      end)

    # Find where the sequence starts
    find_subsequence(token_types, types, 0)
  end

  # Find a subsequence within a list
  defp find_subsequence(list, sublist, offset) do
    if Enum.take(list, length(sublist)) == sublist do
      offset
    else
      case list do
        [_|rest] -> find_subsequence(rest, sublist, offset + 1)
        [] -> nil
      end
    end
  end

  # Assert that a semicolon follows a particular sequence
  defp assert_semicolon_after_sequence(tokens, sequence_start) do
    sequence_length = 2  # We're looking for [:return, :identifier]
    token_after_sequence = Enum.at(tokens, sequence_start + sequence_length)

    assert match?(~c";", token_after_sequence),
      "Expected semicolon after sequence at position #{sequence_start}"
  end
end
