# Opal

A language inspired by Ruby and Elixir, and which compiles to BEAM VM.

## Example

```elixir
module Fibonacci do
  fn fib(0) do 0 end
  fn fib(1) do 1 end
  fn fib(x) do
    fib(x - 1) + fib(x - 2)
  end
end
```

## Setup

```bash
# Choose one:
sudo apt install elixir # for Debian/Ubuntu
sudo dnf install elixir # for Fedora
sudo zypper install elixir # for SUSE/openSUSE
```

## Running

Run a file:
```bash
$ mix opal examples/the_answer.opal
42
```

Compile a file:
```bash
$ mix opal --compile examples/the_answer.opal
```

Run code directly from Elixir:
```bash
$ iex -S mix
iex(1)> Opal.run("fn the_answer_to_everything() do 42 end the_answer_to_everything()")
42
```

## Compile & Install

```bash
MIX_ENV=prod mix do escript.build + escript.install
```

This will install opal to `~/.mix/escripts/opal`. Ensure `~/.mix/escripts` is in your `$PATH`.

To uninstall:
```bash
MIX_ENV=prod mix escript.uninstall opal
```

## Testing

```bash
mix test --trace
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `opal` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:opal, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/opal>.

