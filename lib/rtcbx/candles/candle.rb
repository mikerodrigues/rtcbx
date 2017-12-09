class RTCBX 
  class Candles < RTCBX
    class Candle

      # Candle values, this is standard
      attr_reader :time, :low, :high, :open, :close, :volume

      # Create a new +Candle+ from an epoch, and all the messages sent during
      # the interval of the candle
      def initialize(epoch, matches)
        @time = Time.at(epoch)
        @low = matches.map {|message| BigDecimal.new(message.fetch('price'))}.min
        @high = matches.map {|message| BigDecimal.new(message.fetch('price'))}.max
        @open = BigDecimal.new(matches.first.fetch('price'))
        @close = BigDecimal.new(matches.last.fetch('price'))
        @volume = matches.reduce(BigDecimal(0)) {|sum, message| sum + BigDecimal.new(message.fetch('size'))}
      end

      # Return a +Hash+ representation of the +Candle+
      def to_h
        {
          start:  Time.at(@time),
          low:    @low.to_s("F"),
          high:   @high.to_s("F"),
          open:   @open.to_s("F"),
          close:  @close.to_s("F"),
          volume: @volume.to_s("F"),
        }
      end
    end
  end
end
