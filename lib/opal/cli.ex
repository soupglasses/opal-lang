defmodule Opal.CLI do
  def main(args) do
    # TODO: Guard compile with `--compile`
    case args do
      [path] ->
        {:ok, contents} = File.read(path)
        Opal.compile_to_file(contents, [path: path])
        #Opal.run(contents, [path: path])
      _ -> IO.puts("Usage: opal <FILE>")
    end
  end
end
