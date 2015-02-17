require 'net/http'
require 'json'

module RubyInspector
  class << self
    attr_accessor :current_request_tracker, :socket
    def connect
      @socket = TCPSocket.new 'localhost', 8124
      socket.puts(::JSON.generate({
        method: "RubyInspector.initialize",
        params:{
          name: "My app",
          type: :ruby,
          description: "opens uris like a boss"
        }
      }))
    end
  end

  class RequestTracker

    def self.next_request_id
      @current_request_id ||= 0
      @current_request_id += 1
    end

    attr_reader :request, :address, :port, :response, :body

    def response=(response)
      @response = response
      notify_response_received
    end

    def request_id
      @request_id ||= self.class.next_request_id.to_s
    end

    def body=(body)
      @body = body
      notify_body_received
    end

    def initialize(request, address, port)

      @request = request
      @address = address
      @port = port

      notify_request_started
    end

    def notify_request_started
      data = {
        method: "Network.requestWillBeSent",
        params: {
          requestId: request_id,
          request: {
            url: "http://#{@address}:#{@port}#{request.path}",
            method: request.method,
            headers: Hash[request.each_header.to_a]
          },
          timestamp: Time.now.to_f,
          type: "Other"
        }
      }
      RubyInspector.socket.puts(::JSON.generate(data))
    end

    def notify_response_received
      headers = Hash[response.each_header.to_a]
      data = {
        method: "Network.responseReceived",
        params:{
          requestId: request_id,
          timestamp: Time.now.to_f,
          type:"Document",
          response:{
            url: "http://#{@address}#{request.path}",
            status: response.code,
            statusText: response.message,
            headers: headers,
            mimeType: "text/html",
            requestHeaders: Hash[request.each_header.to_a],
            remotePort: port,
          }
        }
      }
      RubyInspector.socket.puts(::JSON.generate(data))
    end

    def notify_body_received

      data2 = {
        method: "RubyInspector.network.cacheBody",
        params: { requestId: request_id },
        result: {
          body: body,
          base64Encoded: false
        }
      }
      RubyInspector.socket.puts(::JSON.generate(data2))
      sleep 2
      data1 = {
        method: "Network.loadingFinished",
        params: {
          requestId: request_id,
          timestamp: Time.now.to_f,
          encodedDataLength: body.length
        }
      }
      RubyInspector.socket.puts(::JSON.generate(data1))

    end
  end

  connect
end

module Net
  class HTTP
    alias_method(:orig_request, :request) unless method_defined?(:orig_request)
    alias_method(:orig_connect, :connect) unless method_defined?(:orig_connect)

    def request(req, body = nil, &block)
      ::RubyInspector.current_request_tracker = ::RubyInspector::RequestTracker.new(
        req, @address, @port
      )
      body = ''
      block_provided = block_given?
      response = orig_request(req, body ) { |resp|
        resp.read_body { |str| body << str }
        resp.define_singleton_method(:read_body) do |&block|
          block.call(body) unless block.nil?
        end
        block.call(resp) if block_provided
      }

      ::RubyInspector.current_request_tracker.response = response
      ::RubyInspector.current_request_tracker.body = body
      response
    end
  end
end
