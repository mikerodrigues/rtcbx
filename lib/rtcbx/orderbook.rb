require 'rtcbx/orderbook/book_methods'
require 'rtcbx/orderbook/book_analysis'

# This class represents the current state of the CoinBase Exchange orderbook.
#
class RTCBX
  class Orderbook < RTCBX
    include BookMethods
    include BookAnalysis

    # Array of bids
    #
    attr_reader :bids

    # Array of asks
    #
    attr_reader :asks

    # Sequence number from the initial level 3 snapshot
    #
    attr_reader :snapshot_sequence

    # Sequence number of most recently received message
    #
    attr_reader :last_sequence

    # Reads from the queue and updates the Orderbook.
    #
    attr_reader :update_thread

    # Creates a new live copy of the orderbook.
    #
    # If +start+ is set to false, the orderbook will not start automatically.
    #
    # If a +block+ is given it is passed each message as it is received.
    #
    def initialize(options={}, &block)
      @bids = []
      @asks = []
      @snapshot_sequence = 0
      @last_sequence = 0
      super(options, &block)
    end

    # Used to start the thread that listens to updates on the websocket and
    # applies them to the current orderbook to create a live book.
    #
    def start!
      super
      sleep 1
      apply_orderbook_snapshot
      start_update_thread
    end

    # Stop the thread that listens to updates on the websocket
    #
    def stop!
      super
      update_thread.kill
    end

    private

    # Converts an order array from the API into a hash.
    #
    def order_to_hash(price, size, order_id)
      { price:    BigDecimal.new(price),
        size:     BigDecimal.new(size),
        order_id: order_id
      }
    end

    # Fetch orderbook snapshot from API and convert order arrays to hashes.
    #
    def apply_orderbook_snapshot
      client.orderbook(level: 3) do |resp|
        @bids = resp['bids'].map { |b| order_to_hash(*b) }
        @asks = resp['asks'].map { |a| order_to_hash(*a) }
        @snapshot_sequence = resp['sequence']
        @last_sequence = resp['sequence']
      end
    end

    # Private method to actually start the thread that reads from the queue and
    # updates the Orderbook state
    def start_update_thread
      @update_thread = Thread.new do
        begin
          loop do
            message = queue.pop
            apply(message)
          end

        rescue => e
          puts e
        end
      end
    end
  end
end
