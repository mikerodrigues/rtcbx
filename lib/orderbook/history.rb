class Orderbook
  module History

    attr_reader :epochs
    attr_reader :history_queue
    attr_reader :process_epochs
    attr_reader :process_candles
    attr_reader :current_minute
    attr_reader :start_minute

    attr_reader :client

    def start!
##      Timecop.travel(Time.at(JSON.parse(@client.server_epoch).fetch('epoch')))

      #
      # Calculate the first minute to start relying on just the websocket for
      # data.
      #
      initial_time = Time.now
      first_minute = initial_time.to_i + (60 - initial_time.sec)
      @history_queue = Queue.new

      @on_message << lambda do |message|
        if message.fetch('type') == 'match'
          if Time.parse(message.fetch('time')) >= Time.at(first_minute)
            @history_queue << message
          end
        end
      end

      @process_epochs= Thread.new do
        @epochs = {}
        @current_minute = first_minute
        @epochs[@current_minute.to_i] = []

        loop do
          message = @history_queue.pop
          timestamp = Time.parse(message.fetch('time'))
          minute = timestamp.to_i - timestamp.sec
          if minute > @current_minute
            @current_minute = minute
            @epochs[@current_minute.to_i] = []
            @epochs[@current_minute.to_i] << message
          else
            @epochs[@current_minute.to_i] << message
          end
        end
      end

      @process_candles = Thread.new do
        @candles = []
        sleep(60 - Time.now.sec)
        loop do
          @epochs.keys.each do |key|
            if key + 60 <= Time.now.to_i
              @candles << Candle.new(key, @epochs[key]) unless @epochs[key].empty?
              @epochs.delete(key)
            end
          end
          sleep 60
        end
      end
    end

    def candles
      @candles
      #@candles.map do |candle|
      #  { 'start' => Time.at(item[0]),
      #    'low' => item[1],
      #    'high' => item[2],
      #    'open' => item[3],
      #    'close' => item[4],
      #    'volume' => item[5]
      #  }
    end
  end
end
