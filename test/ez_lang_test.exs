defmodule EzLangTest do
  use ExUnit.Case
  doctest EzLang

  test "greets the world" do
    assert EzLang.hello() == :world
  end
end
