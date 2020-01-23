defmodule KV.Registry do
    use GenServer

    @prefix_consumer :consumer
    @prefix_publisher :publisher

    def start_link(opts) do
        server = Keyword.fetch!(opts, :name)
        GenServer.start_link(__MODULE__, server, name: __MODULE__)
    end

    def get_publisher() do
        GenServer.call(KV.Registry, :get_publisher)
    end

    def get_consumer() do
        GenServer.call(KV.Registry, :get_consumer)
    end

    def get_queue() do
        GenServer.call(KV.Registry, :get_queue)
    end

    def insert_consumer(name) do
        GenServer.cast(KV.Registry, {:insert_consumer, name})
    end

    def insert_publisher(name) do
        GenServer.cast(KV.Registry, {:insert_publisher, name})
    end

    def init(table_name) do
        table = :ets.new(table_name, [])
        :ets.insert(table, { @prefix_consumer, []})
        :ets.insert(table, { @prefix_publisher, []})
        a = [
            "consumer_queue_1", "consumer_queue_2", "consumer_queue_3", "consumer_queue_4", "consumer_queue_5", "consumer_queue_6"
        ]
        :ets.insert(table, {:queues, a})
        {:ok, table}
    end

    def handle_cast({:insert_consumer, name}, table) do
        [{_, names}] = :ets.lookup(table, @prefix_consumer)
        :ets.insert(table, { @prefix_consumer, [name | names]})
        {:noreply, table}
    end

    def handle_cast({:insert_publisher, name}, table) do
        [{_, names}] = :ets.lookup(table, @prefix_publisher)
        :ets.insert(table, {@prefix_publisher, [name | names]})
        {:noreply, table}
    end

    def handle_call(:get_consumer, _from, table) do
        [{_, names}] = :ets.lookup(table, @prefix_consumer)
        result = Enum.take_random(names, 1) |> List.first
        {:reply, result, table}
    end

    def handle_call(:get_publisher, _from, table) do
        [{_, names}] = :ets.lookup(table, @prefix_publisher)
        result = Enum.take_random(names, 1) |> List.first
        {:reply, result, table}
    end
    def handle_call(:get_queue, _from, table) do
        [{_, names}] = :ets.lookup(table, :queues)
        result = Enum.take_random(names, 1) |> List.first
        {:reply, result, table}
    end
  end