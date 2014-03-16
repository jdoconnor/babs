# Babs

Do you like RabbitMQ, but want to use it for more than asynchronous messaging?  This will help.  Babs is a Rabbit client using the Bunny gem that goes through the motions of setting up a listener, sending a message and waiting for a response on the listener queue.

Most of this code came from the Bunny tutorials.  The client wrapper and opinions were added on for this gem.

This is demonstration quality code (debug output is left in).  If you like it, let me know and we'll knock it out and set up better automated tests.

Why would someone want to do this??  Isn't this better served with DCell?  Yes, but no.  RabbitMQ will act as your broker, elminating the need for a directory server that remembers where all of your nodes are.

tl;dr - See the usage section

## Installation

Add this line to your application's Gemfile:

    gem 'babs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install babs

## Usage

```ruby
require 'babs/client'

client = Babs::Client.new(server_queue: 'rpc_queue')

(1..1000).each do |c|
  response = client.request(method: :fib, params: { number: 20 })
  # response is a Hashie::Mash of the response (the resonse is expected to be a json string)
  puts "i got this #{response.data.value}"
end

client.close_connection
```

What's a consumer (where you send the request) look like? -- it return a json string.  This is important.
```ruby
#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"
require 'hashie'
require 'json'

conn = Bunny.new(:automatically_recover => false)
conn.start

ch   = conn.create_channel

class FibonacciServer

  def initialize(ch)
    @ch = ch
  end

  def start(queue_name)
    @q = @ch.queue(queue_name, durable: true)
    @x = @ch.default_exchange

    @q.subscribe(:block => true, ack: true) do |delivery_info, properties, payload|
      req = Hashie::Mash.new(JSON.parse(payload))
      if req[:method] == 'fib'
        n = req.params.number.to_i
        r = self.class.fib(n)
        puts " [.] fib(#{n})"
        data_string = {data: { value: r } }.to_json
        @x.publish(data_string, :routing_key => properties.reply_to, :correlation_id => properties.correlation_id)
        @ch.acknowledge(delivery_info.delivery_tag, false)
      end
    end
  end


  def self.fib(n)
    case n
    when 0 then 0
    when 1 then 1
    else
      fib(n - 1) + fib(n - 2)
    end
  end
end

begin
  server = FibonacciServer.new(ch)
  " [x] Awaiting RPC requests"
  server.start("rpc_queue")
rescue Interrupt => _
  ch.close
  conn.close

  exit(0)
end

```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/babs/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
