defmodule Opal.CLI do
  @help_text """
  opal - A functional and parallel programming language

  USAGE:
      opal [OPTIONS] FILE [ARGS...]

  ARGUMENTS:
      FILE                    Path to the file to process
      ARGS                    Arguments to pass to the program

  OPTIONS:
      -c, --compile          Compile the specified file
      -h, --help             Show this help message and exit
      -v, --verbose          Enable verbose output for detailed information

  EXAMPLES:
      opal --help            Show this help message
      opal FILE              Run FILE
      opal FILE arg1 arg2    Run FILE with arguments
      opal -c FILE           Compile FILE
      opal -v FILE           Run FILE with detailed output

  For more information, visit: https://github.com/soupglasses/opal-lang
  """

  def main(args) do
    case parse_args(args) do
      {:help} -> show_help()
      {:error, reason} -> show_error(reason)
      {:ok, path, program_args, options} -> process_file(path, program_args, options)
    end
  end

  defp parse_args(args) do
    {parsed_opts, path_and_args, []} = OptionParser.parse(args,
      aliases: [c: :compile, h: :help, v: :verbose],
      strict: [compile: :boolean, help: :boolean, verbose: :boolean]
    )

    cond do
      should_show_help?(parsed_opts) -> {:help}
      Enum.empty?(path_and_args) -> {:error, "No file specified"}
      compile_with_args?(parsed_opts, path_and_args) -> {:error, "Arguments cannot be passed when compiling"}
      true ->
        [path | program_args] = path_and_args
        {:ok, path, program_args, build_options(parsed_opts)}
    end
  end

  defp should_show_help?(parsed_opts) do
    Keyword.get(parsed_opts, :help, false)
  end

  defp compile_with_args?(parsed_opts, path_and_args) do
    Keyword.get(parsed_opts, :compile, false) and length(path_and_args) > 1
  end

  defp build_options(parsed_opts) do
    [
      compile: Keyword.get(parsed_opts, :compile, false),
      verbose: Keyword.get(parsed_opts, :verbose, false)
    ]
  end

  defp show_help do
    IO.puts(@help_text)
  end

  defp show_error(message) do
    IO.puts("Error: #{message}")
    IO.puts("Use --help for usage information.")
  end

  defp process_file(path, program_args, options) do
    case File.read(path) do
      {:ok, contents} -> 
        execute_command(contents, path, program_args, options)
      {:error, reason} -> 
        show_error("Could not read file '#{path}': #{reason}")
    end
  end

  defp execute_command(contents, path, program_args, options) do
    opts = options
           |> Keyword.put(:path, path)
           |> Keyword.put(:args, program_args)
    
    if Keyword.get(options, :compile, false) do
      Opal.compile_to_file(contents, opts)
    else
      Opal.run(contents, opts)
    end
  end
end
