defmodule Pabbot do
    
    def test do
        
        a = fn _a ->
            Pabbot.Publisher.Channel.publish()
        end
        
        1..2_000_000
        |> Task.async_stream(a, max_concurrency: 2)
        |> Enum.to_list()
    end

end
