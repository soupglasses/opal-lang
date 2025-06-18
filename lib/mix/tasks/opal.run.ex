defmodule Mix.Tasks.Opal.Run do
  use Mix.Task

  @shortdoc "Run an Opal file directly with arguments"
  def run([path | tail]) do
    {:ok, contents} = File.read(path)
    Opal.run(contents, [path: path, args: tail])
  end
end
