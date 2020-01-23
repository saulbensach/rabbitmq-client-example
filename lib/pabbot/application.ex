defmodule Pabbot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @read_connections 8
  @write_connections 1

  def start(_type, _args) do
    children = [
      {KV.Registry, [name: :pool_names]},
      :poolboy.child_spec(:pool_consumer_connection, pool_consumer_connection_config()),
      :poolboy.child_spec(:pool_publisher_connection, pool_publisher_connection_config())
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pabbot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp pool_consumer_connection_config do
    [
      {:name, {:local, :consumer_connection_pool}},
      {:worker_module, Pabbot.Consumer.Connection.Worker},
      {:size, @read_connections},
      {:max_overflow, @read_connections}
    ]
  end

  defp pool_publisher_connection_config do
    [
      {:name, {:local, :publisher_connection_pool}},
      {:worker_module, Pabbot.Publisher.Connection.Worker},
      {:size, @write_connections},
      {:max_overflow, @write_connections}
    ]
  end
end
