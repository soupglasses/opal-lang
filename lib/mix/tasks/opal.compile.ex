defmodule Mix.Tasks.Opal.Compile do
  use Mix.Task

  @shortdoc "Compile an Opal file"
  def run([path]) do
    {:ok, contents} = File.read(path)
    Opal.compile_to_file(contents, [path: path])
  end
end
