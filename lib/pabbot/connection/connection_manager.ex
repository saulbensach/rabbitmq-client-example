defmodule Pabbot.Connection.Manager do
    @moduledoc false

    defmacro __using__(opts) do
        role = Keyword.get(opts, :role)

        quote do
            use GenServer
            use AMQP

            import Logger

            alias AMQP.Connection
            alias AMQP.Channel

            @reconnect_interval 10_000
            @host "amqp://guest:guest@localhost"
            @workers 10
            
            def start_link(_) do
                GenServer.start_link(__MODULE__, [], [])
            end

            def init(_opts) do
                send(self(), :connect)
                {:ok, nil, 5_000_000}
            end

            def handle_info(:connect, conn) do
                open_connection(@host)
            end

            def handle_call(:create_channel, _from, conn) do
                result = Channel.open(conn)
                {:reply, result, conn}
            end

            def handle_cast(:publish, conn) do
                :poolboy.transaction(:pool_publisher_channel, fn pid -> GenServer.cast(pid, :publish) end)
                {:noreply, conn}
            end

            def handle_info({:DOWN, _, :process, _pid, reason}, _) do
                {:stop, {:connection_lost, reason}, nil}
            end

            defp open_connection(host) do
                host
                |> Connection.open
                |> retrieve_result
                |> create_pool
            end
        
            defp retrieve_result({:ok, conn}) do
                Logger.info("RabbitMQ Connection started!")
                Process.monitor(conn.pid)
                {:continue, conn}
            end
            defp retrieve_result({:error, reason} = result) do
                Logger.error("Unable to start RabbitMQ Connection at #{@host} retriying...")
                Process.send_after(self(), :connect, @reconnect_interval)
                :retry
            end

            defp create_pool({:continue, conn}) do
                pool_name = String.to_atom("pool_#{unquote(role)}_channel")
                children = [
                    :poolboy.child_spec(pool_name, pool_config(), self()),
                ]
                opts = [strategy: :one_for_one]
                # What to do with the supervisor?
                Supervisor.start_link(children, opts)
                {:noreply, conn}
            end
            defp create_pool(:retry) do
                {:noreply, nil}
            end

            defp pool_config do
                pool_name = get_pool_name()
                module = fn -> 
                    if unquote(role) == :consumer do
                        KV.Registry.insert_consumer(pool_name)
                        Pabbot.Consumer.Channel
                    else
                        KV.Registry.insert_publisher(pool_name)
                        Pabbot.Publisher.Channel
                    end
                end

                hack = fn -> 
                    if unquote(role) == :consumer do
                        @workers
                    else
                        10
                    end
                end
                
                [   
                    {:name, {:local, pool_name}},
                    {:worker_module, module.()},
                    {:size, hack.()},
                    {:max_overflow, hack.()}
                ]
            end

            defp get_pool_name() do
                Enum.to_list(?a..?z)
                |> Enum.take_random(6)
                |> List.to_string
                |> String.to_atom
            end
        end
    end
end