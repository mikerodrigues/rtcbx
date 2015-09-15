require 'rtcbx/candles/candle'

class RTCBX
  class Candles < RTCBX

    attr_reader :buckets
    attr_reader :history_queue
    attr_reader :update_thread
    attr_reader :bucket_thread
    attr_reader :candle_thread
    attr_reader :current_bucket
    attr_reader :start_minute
    attr_reader :candles

    attr_reader :initial_time
    attr_reader :first_bucket


    def initialize(options = {}, &block)
      super(options, &block)
    end

    def start!
      super
      #
      # Calculate the first minute to start relying on just the websocket for
      # data.
      #
      @initial_time = Time.now
      @first_bucket = initial_time.to_i + (60 - initial_time.sec)
      @history_queue = Queue.new

      start_bucket_thread
      start_candle_thread
    end

    private


#    def start_update_thread
#      @update_thread = Thread.new do
#        loop do
#          event = queue.pop
#          if event.fetch('type') == 'match'
#            #
#            #this is a stupid check
#            #
#            if Time.parse(event.fetch('time')) >= Time.at(first_bucket)
#              @history_queue << event
#            end
#          end
#        end
#      end
#    end

    def start_bucket_thread
      @bucket_thread = Thread.new do
        @buckets = {}
        @current_bucket = first_bucket
        @buckets[current_bucket.to_i] = []

        loop do
          message = queue.pop
          if message.fetch('type') == 'match'
            if Time.parse(message.fetch('time')) >= Time.at(first_bucket)
              timestamp = Time.parse(message.fetch('time'))
              bucket = timestamp.to_i - timestamp.sec
              if bucket > current_bucket
                @current_bucket = bucket 
                @buckets[current_bucket.to_i] = []
                @buckets[current_bucket.to_i] << message
              else
                @buckets[current_bucket.to_i] << message
              end
            end
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
              @candles << Candle.new(key, buckets[key]) unless buckets[key].empty?
              buckets.delete(key)
            end
          end

          sleep 60
        end
      end
    end
  end
end