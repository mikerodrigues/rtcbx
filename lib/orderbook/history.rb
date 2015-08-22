class Orderbook
  module History

    attr_reader: candles

    @candles = {}

    def collect candles
      start_time = Time.at JSON.parse(@client.server_epoch)

      #
      # Calculate the first minute to start relying on just the websocket for
      # data.
      #
      first_minute = start_time + (60 - start_time)
      @history_queue = Queue.new

      message_callback = lambda do |message|
        if message.fetch('type') == 'match'
          if Time.parse(message.fetch('time')) <= first_minute
            @history_queue << message
          end
        end
      end

      @candle_processor = Thread.new do
        current_minute = first_minute
        @candles[current_minute.to_i] = []
        @history_queue.shift do |m|
          timestamp = Time.at(m.fetch('time'))
          minute = timestamp + (60 - timestamp)
          if minute > current_minute
            current_minute = minute
            @candles[current_minute.to_i] = []
            @candles[current_minute.to_i] << m
          else
            @candles[current_minute.to_i] << m
          end
        end
      end
    end
  end
end
