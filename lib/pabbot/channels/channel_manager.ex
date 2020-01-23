defmodule Pabbot.Channel.Manager do
    @moduledoc false

    defmacro __using__(opts) do
        queue_name = Keyword.get(opts, :queue_name)
        role = Keyword.get(opts, :role)

        quote do
            use GenServer

            import Pabbot.Channel.Manager

            alias AMQP.Queue
            alias AMQP.Basic

            @queue unquote(queue_name)

            def start_link(pid) do
                GenServer.start_link(__MODULE__, pid, [])
            end
        
            def init(pid) do
                send(self(), {:ask_for_channel, pid})
                {:ok, nil, 5_000_000}
            end
        
            def handle_info({:ask_for_channel, pid}, chan) do
                {:ok, chan} = GenServer.call(pid, :create_channel, 5_000_000)
                Process.monitor(chan.pid)
                if unquote(role) == :consumer do
                    name = KV.Registry.get_queue()
                    {:ok, queue} = Queue.declare(chan, name)
                    AMQP.Exchange.declare(chan, "#{@queue}_exchange", :direct)
                    AMQP.Queue.bind(chan, queue.queue, "#{@queue}_exchange")
                    {:ok, _consumer_tag} = Basic.consume(chan, queue.queue)
                end
                {:noreply, chan}
            end
        end
    end
end