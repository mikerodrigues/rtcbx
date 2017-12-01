require 'coinbase/exchange'
require 'rtcbx/orderbook'
require 'rtcbx/candles'
require 'rtcbx/trader'
require 'rtcbx/version'
require 'eventmachine'

class RTCBX
  # seconds in between pinging the connection.
  #
  PING_INTERVAL = 15

  attr_reader :product_id
  attr_reader :start
  attr_reader :api_key
  attr_reader :message_callbacks
  attr_reader :websocket
  attr_reader :client
  attr_reader :queue
  attr_reader :last_pong
  attr_reader :websocket_thread

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

  def start!
    start_websocket_thread
  end

  def stop!
    websocket_thread.kill
    websocket.stop!
  end

  def reset!
    stop!
    start!
  end

  private

  attr_reader :api_secret
  attr_reader :api_passphrase

  def setup_websocket_callback
    websocket.message do |message|
      queue.push(message)
      message_callbacks.each { |b| b.call(message) unless b.nil? }
    end
  end

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

  def setup_ping_timer
    EM.add_periodic_timer(PING_INTERVAL) do
      websocket.ping do
        @last_pong = Time.now
      end
    end
  end

  def setup_error_handler
    EM.error_handler do |e|
      print "Websocket Error: #{e.message} - #{e.backtrace.join("\n")}"
    end
  end
end
