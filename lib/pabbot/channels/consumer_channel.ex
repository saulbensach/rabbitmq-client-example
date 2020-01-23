defmodule Pabbot.Consumer.Channel do
    @moduledoc false

    use Pabbot.Channel.Manager, queue_name: "consumer_queue", role: :consumer

    # Confirmation sent by the broker after registering this process as a consumer
    def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
        {:noreply, chan}
    end

    # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
    def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, chan) do
        {:stop, :normal, chan}
    end

    # Confirmation sent by the broker to the consumer process after a Basic.cancel
    def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, chan) do
        {:noreply, chan}
    end

    def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, chan) do
        spawn fn -> 
            :timer.sleep(1000)
            :ok = AMQP.Basic.ack(chan, tag)
        end
        {:noreply, chan}
    end
end