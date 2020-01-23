defmodule Pabbot.Publisher.Channel do
    @moduledoc false

    use Pabbot.Channel.Manager, queue_name: "publisher_queue", role: :publisher

    def publish() do
        pool = KV.Registry.get_publisher()
        :poolboy.transaction(pool, fn pid -> 
            GenServer.cast(pid, :publish) 
        end)
    end

    def handle_cast(:publish, chan) do
        AMQP.Basic.publish(chan, "consumer_queue_exchange", "", "Hello, World!")
        {:noreply, chan}
    end

    def handle_info({:DOWN, _, :process, _pid, reason}, _) do
        {:stop, {:channel_closed, reason}, nil}
    end

end