defmodule Opal.CompilerTest do
  use ExUnit.Case
  doctest Opal.Compiler
  alias Opal.Compiler

  describe "generate_core/1" do
    test "compiles integer literals" do
      #assert false
    end

    test "handles error cases" do
      #ast = {:unknown_node_type, 42}
      #assert {:error, _} = Compiler.generate_core(ast)
    end
  end
end
