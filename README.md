# RTCBX 

RTCBX uses the Coinbase (now GDAX) Exchange websocket feed to provide immediate access to
the current state of the exchange without repeatedly polling parts of the
RESTful API. It can:
* Keep a synchronized copy of the entire orderbook - `RTCBX::Orderbook`
* Calculate historic rates (candles) by the minute - `RTCBX::Candles`
* Place and track orders for an account - `RTCBX::Trader`

Each type of RTCBX object will supports defining callbacks to run when:
* The `Orderbook` changes.
* A new candle is generated.
* Your order(s) change status.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rtcbx'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rtcbx 

## Usage

```ruby
require 'rtcbx'
```
RTCBX objects share a common interface:
```ruby
#
# :product_id
#   sets the currency (defaults to 'BTC-USD)
#
# :start
#   run #start! at creation?  (defaults to true)
# 

rtcbx = RTCBX.new({product_id: 'BTC-GPB', start: false}) do |change|
  # check some values, do some stuff
end

rtcbx.start! # Starts the websocket feed and tracking/update threads.

rtcbx.stop!  # Stops the websocket feed and any tracking/update threads.

rtcbx.reset! # Calls #stop! then calls #start!.

```




* Create a live updating Orderbook:
```ruby
ob = RTCBX::Orderbook.new
```

* Create an Orderbook object but don't fetch an orderbook or start live
  updating.
```ruby
ob = RTCBX::Orderbook.new(start: false)

# When you want it to go live:

ob.start!

# When you want to stop it:

ob.stop!

# Reset the orderbook by fetching a fresh orderbook snapshot. This just calls
# `stop!` and then `start!` again:

ob.reset!
```

* Get the "BTC-GBP" orderbook instead of "BTC-USD":
```ruby
ob = RTCBX::Orderbook.new(product_id: "BTC-GBP")
```

* Create a live Orderbook with a callback to fire on each message:
```ruby
ob = RTCBX::Orderbook.new do |message|
  if message.fetch 'type' == 'match'
    puts ob.spread.to_f('s')
  end
end
```

* Create or reset the message callback:
```ruby
ob.on_message do |message|
  puts ob.count
end
```

* List current bids:
```ruby
ob.bids
```

* List current asks:
```ruby
ob.asks
```

* Show sequence number for initial level 3 snapshot:
```ruby
ob.snapshot_sequence
```

* Show sequence number for the last message received
```ruby
ob.last_sequence
```

* Show the last Time a pong was received after a ping (ensures the connection is
  still alive):
```ruby
ob.last_pong
```

## Contributing

1. Fork it ( https://github.com/mikerodrigues/orderbook/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
