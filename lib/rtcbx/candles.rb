class RTCBX
  class Candles

    attr_reader :buckets
    attr_reader :history_queue
    attr_reader :bucket_thread
    attr_reader :candle_thread
    attr_reader :current_minute
    attr_reader :start_minute
    attr_reader :candles

    attr_reader :initial_time
    attr_reader :first_minute

    attr_reader :client
    attr_reader :websocket

    def initialize(product_id: "BTC-USD", start: true, &block)
      @product_id = product_id
      @on_message = []
    end

    def start!
      #
      # Calculate the first minute to start relying on just the websocket for
      # data.
      #
      @initial_time = Time.now
      @first_minute = initial_time.to_i + (60 - initial_time.sec)
      @history_queue = Queue.new

      setup_websocket_callback
      start_bucket_thread
      start_candle_thread
    end

    private

    def setup_websocket_callback
      websocket.message do |message|
        if message.fetch('type') == 'match'
          if Time.parse(message.fetch('time')) >= Time.at(first_minute)
            history_queue << message
          end
        end
      end
    end

    def start_bucket_thread
      @bucket_thread = Thread.new do
        @buckets = {}
        current_minute = first_minute
        buckets[current_minute.to_i] = []

        loop do
          message = history_queue.pop
          timestamp = Time.parse(message.fetch('time'))
          minute = timestamp.to_i - timestamp.sec
          if minute > current_minute
            current_minute = minute
            buckets[current_minute.to_i] = []
            buckets[current_minute.to_i] << message
          else
            buckets[current_minute.to_i] << message
          end
        end
      end
    end

    def start_candle_thread
      @candle_thread = Thread.new do
        @candles = []
        sleep(60 - Time.now.sec)
        loop do
          buckets.keys.each do |key|
            if key + 60 <= Time.now.to_i
              candles << Candle.new(key, buckets[key]) unless buckets[key].empty?
              buckets.delete(key)
            end
          end

          sleep 60
        end
      end
    end
  end
end
