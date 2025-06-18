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

  def compile(code, opts \\ []) do
    with {:ok, ast} <- parse(code) do
      Compiler.compile(ast, Keyword.get(opts, :path))
      |> tap(fn line -> if Keyword.get(opts, :verbose, false), do: IO.inspect(line) end)
      |> :compile.forms(
        [:from_core, :verbose, :return] ++ Keyword.get(opts, :compiler_opts, [:report])
      )
    end
  end

  def compile_to_file(code, opts \\ []) do
    # Create default filename be `./a.out` if no path is given, mimmicing GNU C compiler.
    filename =
      case Keyword.get(opts, :path, "a") do
        path when binary_part(path, byte_size(path) - 5, 5) == ".opal" ->
          String.replace_suffix(path, ".opal", "")

        path ->
          path <> ".out"
      end

    {:ok, _module_name, binary, _warnings} = compile(code, opts)
    {:ok, escript_binary} = :escript.create(:binary, [:shebang, {:beam, binary}])

    # TODO: Check if moduleize(path) == module_name before writing? Avoids `cat.opal` containing `module Dog do ... end` confusion.
    File.write!(filename, escript_binary)
    File.chmod!(filename, 0o755)

    {:ok, filename}
  end

  def to_core(code, opts \\ []) do
    with {:ok, ast} <- parse(code) do
      Compiler.compile(ast)
      |> tap(fn line -> if Keyword.get(opts, :verbose, false), do: IO.inspect(line) end)
      |> :core_pp.format()
      |> :erlang.iolist_to_binary()
    end
  end

  def load(code, opts \\ []) do
    path =
      case Keyword.get(opts, :path) do
        nil -> ~c"nopath"
        path -> to_charlist(path)
      end

    with {:ok, module_name, binary, _warnings} <- compile(code, opts) do
      :code.load_binary(module_name, path, binary)
    end
  end

  def run(code, opts \\ []) do
    args = Keyword.get(opts, :args, []) |> Enum.map(&Kernel.to_charlist/1)

    with {:module, module} <- load(code, opts) do
      module.main(args)
    end
  end
end
