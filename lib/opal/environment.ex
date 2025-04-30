defmodule Opal.Environment do
  @moduledoc """
  Environment store for the Opal Language

  Management of variable bindings and scopes during execution
  """
  @type t :: %__MODULE__{
    bindings: map(),
    parent: t() | nil
  }

  defstruct bindings: %{}, parent: nil


  @doc """
  Creates empty environment
  Examples:
      iex> Opal.Environment.new()
      %Opal.Environment{bindings: %{}, parent: nil}
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}


  @doc """
  New environment with given parent environment
  """
  @spec extend(t()) :: t()
  def extend(parent), do: %__MODULE__{parent: parent}


  @doc """
  Looks up variable in environment.
  Follows scope chain, if variable not found in current scope

  Returns `{:ok, value}` if the variable is found, or `{:error, :undefined_variable}`
  if the variable is not defined in any accessible scope.
  """
  @spec lookup(t(), atom()) :: {:ok, any()} | {:error, :undefined_variable}
  def lookup(%__MODULE__{bindings: bindings, parent: parent}, name) do
    case Map.fetch(bindings, name) do
      {:ok, value} -> {:ok, value}
      :error when parent != nil -> lookup(parent, name)
      :error -> {:error, :undefined_variable}
    end
  end


  @doc """
  Defines are varable in the environment.
  """
  @spec define(t(), atom(), any()) :: t()
  def define(%__MODULE__{bindings: bindings} = env, name, value) do
    %{env | bindings: Map.put(bindings, name, value)}
  end
end
