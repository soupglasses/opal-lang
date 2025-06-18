defmodule Mix.Tasks.Opal do
  use Mix.Task

  @shortdoc "Run the Opal CLI"
  def run(args) do
    Opal.CLI.main(args)
  end
end
