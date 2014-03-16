module Babs
  class Client
    require "bunny"
    require "thread"
    require "hashie"
    require 'json'

    attr_accessor :route
    attr_accessor :response, :call_id
    attr_reader :lock, :condition
    attr_reader :reply_queue

    def initialize(options = {})
      # make this connection part a singleton and a LOT of time is saved, as well as reusing the same connection
      @conn = Bunny.new(:automatically_recover => false)
      @conn.start
      @ch   = @conn.create_channel

      @defaults = Hashie::Mash.new({
          server_queue: nil,
          exchange: @ch.default_exchange
        }.merge(options)
      )

      @lock      = Mutex.new
      @condition = ConditionVariable.new

    end

    def close_connection
      @ch.close
      @conn.close
    end

    def listen_for_response
      # listen on a new queue for this response
      @reply_queue = @ch.queue("", :exclusive => true)
      @reply_queue.subscribe do |delivery_info, properties, payload|
        puts "response_id #{properties[:correlation_id]}"
        puts properties[:correlation_id] == self.call_id ? "correct id" : "BAD id"
        if properties[:correlation_id] == self.call_id
          self.response = payload
          self.lock.synchronize{self.condition.signal}
        end
      end
    end

    def send_request(routing_options, method, params)
      self.call_id = SecureRandom.uuid

      data_string = {method: method, params: params}.to_json

      routing_options.exchange.publish(
        data_string,
        routing_key:    routing_options.server_queue,
        correlation_id: call_id,
        reply_to:       @reply_queue.name)
      puts "call id #{call_id}"
      self.response = nil
      # params to synchronize are mutex, timeout_in_seconds
      lock.synchronize{condition.wait(lock, 5)}
      response
    end

    def request(options = {})
      options = Hashie::Mash.new(options)
      # grab out the expected data
      method = options.delete(:method)
      params = options.delete(:params)

      # merge the connection options with the defaults
      routing_options = @defaults.merge(options)

      response = listen_for_response
      response = send_request(routing_options, method, params)
      # parse and return response
      Hashie::Mash.new(JSON.parse(response))
    end

  end
end
