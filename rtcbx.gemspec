# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rtcbx/version'

Gem::Specification.new do |spec|
  spec.name          = 'rtcbx'
  spec.version       = RTCBX::VERSION
  spec.authors       = ['Michael Rodrigues']
  spec.email         = ['mikebrodrigues@gmail.com']
  spec.summary       = %q(Maintains an real-time copy of the Coinbase Pro (formerly GDAX,
                          formerly Coinbase Exchange) Exchange order book.)
  spec.description   = %q(Uses the Coinbase Pro (formerly GDAX, formerly Coinbase Exchange) Exchange Websocket stream
                          to maintain a real-time copy of the order book, place and track orders,
                          and calculate historic rates by the minute in real-time.)
  spec.homepage      = 'https://github.com/mikerodrigues/rtcbx'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'coinbase-exchange', '~> 0.2', '>= 0.2.0'
  spec.add_runtime_dependency 'eventmachine', '~> 1.0'
  spec.add_runtime_dependency 'json', '~> 2.0'
  
  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end
