# frozen_string_literal: true

require 'rtcbx/candles/candle'

class RTCBX
  class Candles < RTCBX
    # A hash of buckets
    # Each key is an epoch which stores every +match+ message for that minute
    # (The epoch plus 60 seconds)
    # Each minute interval is a bucket, which is used to calculate that minute's
    # +Candle+
    attr_reader :buckets

    # This thread monitors the websocket object and puts each +match+ object
    # into the proper bucket. This thread maintains the +buckets+ object.
    attr_reader :bucket_thread

    # The +candle_thread+ consumes the buckets created by the +bucket_thread+ in
    # +buckets+ and turns them into +Candle+ objects. These are then appended to
    # the +candles+ array. This functionality could be improved. Ideally you're
    # consuming this array into a database to keep history in realtime.
    attr_reader :candle_thread

    # The epoch representing the current bucket
    attr_reader :current_bucket

    # An array of generated candles. You should process these by putting them
    # into a database and removing them from the array. If you want to help me
    # abstract this to a pluggable database system, open an issue.
    attr_reader :candles

    # The first full minute that we can collect for. (+Time+ object)
    attr_reader :initial_time

    # The epoch of the first bucket
    attr_reader :first_bucket

    # Mutex to allow our two threads to produce and consume +buckets+
    attr_reader :buckets_lock

    # Create a new +Candles+ object to start and track candles
    # Pass a block to run a block whenever a candle is created.
    #
    def initialize(options = {}, &block)
      super(options, &block)
      @buckets_lock = Mutex.new
    end

    # Start tracking candles
    def start!
      super
      #
      # Calculate the first minute to start relying on just the websocket for
      # data.
      #
      @initial_time = Time.now
      @first_bucket = initial_time.to_i + (60 - initial_time.sec)

      start_bucket_thread
      start_candle_thread
    end

    private

    # Start the thread to create buckets
    def start_bucket_thread
      @bucket_thread = Thread.new do
        @buckets = {}
        @current_bucket = first_bucket
        @buckets[current_bucket.to_i] = []

        loop do
          message = queue.pop
          next unless message.fetch('type') == 'match'

          next unless Time.parse(message.fetch('time')) >= Time.at(first_bucket)

          timestamp = Time.parse(message.fetch('time'))
          message_bucket = timestamp.to_i - timestamp.sec
          @buckets_lock.synchronize do
            if message_bucket >= current_bucket
              @current_bucket = message_bucket
              @buckets[current_bucket.to_i] = []
              @buckets[current_bucket.to_i] << message
            else
              @buckets[current_bucket.to_i] << message
            end
          end
        end
      end
    end

    # Start the thread to consume buckets to +Candle+ objects
    def start_candle_thread
      @candle_thread = Thread.new do
        @candles = []
        sleep(60 - Time.now.sec)
        loop do
          buckets.keys.each do |key|
            next unless key + 60 <= Time.now.to_i

            @buckets_lock.synchronize do
              candle = Candle.new(key, buckets[key]) unless buckets[key].empty?
              @candles << candle
              # Run candle callback
              #
              @message_callbacks.each { |c| c.call(candle) }
              buckets.delete(key)
            end
          end

          sleep(60 - Time.now.sec)
        end
      end
    end
  end
end
