require 'coinbase/exchange'
require 'rtcbx/orderbook'
require 'rtcbx/candles'
require 'rtcbx/trader'
require 'rtcbx/version'
require 'eventmachine'

class RTCBX
  # seconds in between pinging the connection.
  #
  PING_INTERVAL = 2

  # The Coinbase Pro product being tracked (eg. "BTC-USD")
  attr_reader :product_id

  # Boolean, whether the orderbook goes live on creation or not
  # If +false+, +#start!+ must be called to initiate tracking.
  attr_reader :start

  # API key used to authenticate to the API
  # Not required for Orderbook or Candles
  attr_reader :api_key

  # An array of blocks to be run each time a message comes in on the Websocket
  attr_reader :message_callbacks

  # The Websocket object
  attr_reader :websocket

  # The Coinbase Pro Client object
  # You can use this if you need to make API calls
  attr_reader :client

  # The message queue from the Websocket.
  # The +websocket_thread+ processes this queue
  attr_reader :queue

  # Epoch time indicating the last time we received a pong from Coinbase Pro in response
  # to one of our pings
  attr_reader :last_pong

  # The thread that consumes the websocket data
  attr_reader :websocket_thread

  # Create a new RTCBX object with options and an optional block to be run when
  # each message is called.
  #
  # Generally you won't call this directly. You'll use +RTCBX::Orderbook.new+,
  # +RTCBX::Trader.new+, or +RTCBX::Candles.new+.
  #
  # You can also subclass RTCBX and call this method through +super+, as the
  # classes mentioned above do.
  #
  # RTCBX handles connecting to the Websocket, setting up the client, and
  # managing the thread that consumes the Websocket feed.
  #
  def initialize(options = {}, &block)
    @product_id     = options.fetch(:product_id, 'BTC-USD')
    @start          = options.fetch(:start, true)
    @api_key        = options.fetch(:api_key, '')
    @api_secret     = options.fetch(:api_secret, '')
    @api_passphrase = options.fetch(:api_passphrase, '')
    @message_callbacks = []
    @message_callbacks << block if block_given?
    @client = Coinbase::Exchange::Client.new(
      api_key,
      api_secret,
      api_passphrase,
      product_id: product_id
    )
    @websocket = Coinbase::Exchange::Websocket.new(
      keepalive: true,
      product_id: product_id
    )
    @queue = Queue.new
    start! if start
  end

  # Starts the thread to consume the Websocket feed
  def start!
    start_websocket_thread
  end

  # Stops the thread and disconnects from the Websocket
  def stop!
    websocket_thread.kill
    websocket.stop!
  end

  # Stops, then starts the thread that consumes the Websocket feed
  def reset!
    stop!
    start!
  end

  private

  attr_reader :api_secret
  attr_reader :api_passphrase

  # Configures the websocket to pass each message to each of the defined message
  # callbacks
  def setup_websocket_callback
    websocket.message do |message|
      queue.push(message)
      message_callbacks.each { |b| b.call(message) unless b.nil? }
    end
  end

  # Starts the thread that consumes the websocket
  def start_websocket_thread
    @websocket_thread = Thread.new do
      setup_websocket_callback
      EM.run do
        websocket.start!
        setup_ping_timer
        setup_error_handler
      end
    end
  end

  # Configures the websocket to periodically ping Coinbase Pro and confirm connection
  def setup_ping_timer
    EM.add_periodic_timer(PING_INTERVAL) do
      websocket.ping do
        @last_pong = Time.now
      end
    end
  end

  # Configures the Websocket object to print any errors to the console
  def setup_error_handler
    EM.error_handler do |e|
      print "Websocket Error: #{e.message} - #{e.backtrace.join("\n")}"
    end
  end
end
