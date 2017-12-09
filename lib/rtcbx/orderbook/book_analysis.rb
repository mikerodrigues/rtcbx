class RTCBX
  class Orderbook < RTCBX
    # Simple collection of commands to get info about the orderbook. Add our own
    # methods for calculating whatever it is you feel like calculating.
    #
    module BookAnalysis
      # Number of all current bids
      def bid_count
        @bids.count
      end

      # Number of all current asks
      def ask_count
        @asks.count
      end

      # Number of all current orders
      def count
        { bid: bid_count, ask: ask_count }
      end

      # The total volume of product across all current bids
      def bid_volume
        @bids.map { |x| x.fetch(:size) }.inject(:+)
      end

      # The total volume of product across all current asks
      def ask_volume
        @asks.map { |x| x.fetch(:size) }.inject(:+)
      end

      # The total volume of all product across current asks and bids
      def volume
        { bid: bid_volume, ask: ask_volume }
      end

      # The average bid price across all bids
      def average_bid
        bids = @bids.map { |x| x.fetch(:price) }
        bids.inject(:+) / bids.count
      end

      # The average ask price across all asks
      def average_ask
        asks = @asks.map { |x| x.fetch(:price) }
        asks.inject(:+) / asks.count
      end

      # The average price across all orders
      def average
        { bid: average_bid, ask: average_ask }
      end

      # The price of the best current bid
      def best_bid
        @bids.sort_by { |x| x.fetch(:price) }.last
      end

      # The price of the best current ask
      def best_ask
        @asks.sort_by { |x| x.fetch(:price) }.first
      end

      # The prices of the best current bid and ask
      def best
        { bid: best_bid, ask: best_ask }
      end

      # The price difference between the best current bid and ask
      def spread
        best_ask.fetch(:price) - best_bid.fetch(:price)
      end

      # Aggregates the +top_n+ current bids. Pass `50` and you'll get the same
      # thing tht GDAX calls a "Level 2 Orderbook"
      def aggregate_bids(top_n = nil)
        aggregate = {}
        @bids.each do |bid|
          aggregate[bid[:price]] ||= aggregate_base
          aggregate[bid[:price]][:size] += bid[:size]
          aggregate[bid[:price]][:num_orders] += 1
        end
        top_n ||= aggregate.keys.count
        aggregate.keys.sort.reverse.first(top_n).map do |price|
          { price: price,
            size: aggregate[price][:size],
            num_orders: aggregate[price][:num_orders]
          }
        end
      end

      # Aggregates the +top_n+ current asks. Pass `50` and you'll get the same
      # thing tht GDAX calls a "Level 2 Orderbook"
      def aggregate_asks(top_n = nil)
        aggregate = {}
        @asks.each do |ask|
          aggregate[ask[:price]] ||= aggregate_base
          aggregate[ask[:price]][:size] += ask[:size]
          aggregate[ask[:price]][:num_orders] += 1
        end
        top_n ||= aggregate.keys.count
        aggregate.keys.sort.first(top_n).map do |price|
          { price: price,
            size: aggregate[price][:size],
            num_orders: aggregate[price][:num_orders]
          }
        end
      end

      # Aggregates the +top_n+ current asks and bids. Pass `50` and you'll get the same
      # thing tht GDAX calls a "Level 2 Orderbook"
      def aggregate(top_n = nil)
        { bids: aggregate_bids(top_n), asks: aggregate_asks(top_n) }
      end

      # print a quick summary of the +Orderbook+
      def summarize
        print "# of asks: #{ask_count}\n# of bids: #{bid_count}\nAsk volume: #{ask_volume.to_s('F')}\nBid volume: #{bid_volume.to_s('F')}\n"
        $stdout.flush
      end

      private

      def aggregate_base
        { size: BigDecimal.new(0), num_orders: 0 }
      end
    end
  end
end
