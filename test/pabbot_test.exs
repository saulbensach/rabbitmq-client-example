defmodule PabbotTest do
  use ExUnit.Case
  doctest Pabbot

  test "greets the world" do
    assert Pabbot.hello() == :world
  end
end
