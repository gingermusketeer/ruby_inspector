require 'net/http'

module Nsa

  class NetHttpTracker
    class<<self
      def on_request(&block)
        if block_given?
          @on_request = block
        else
          @on_request
        end
      end

    end

    attr_reader :protocol, :address, :port, :path, :method, :request_headers,
      :status_code, :status_message, :response_headers, :response_body

    def initialize(protocol, address, port, path, method, headers)
      @protocol = protocol
      @address = address
      @port = port
      @path = path
      @method = method
      @request_headers = headers
      self.class.on_request.call(self)
    end

    def url
      "#{protocol}://#{address}#{path}"
    end

    def on_response(&block)
      if block_given?
        @on_response = block
      else
        @on_response
      end
    end

    def on_body(&block)
      if block_given?
        @on_body = block
      else
        @on_body
      end
    end

    def set_response_info(status_code, status_message, headers)
      @status_code = status_code
      @status_message = status_message
      @response_headers = headers
      self.on_response.call
    end

    def response_body=(body)
      @response_body = body
      self.on_body.call
    end
  end
end

module Net
  class HTTP
    alias_method(:orig_request, :request) unless method_defined?(:orig_request)
    alias_method(:orig_connect, :connect) unless method_defined?(:orig_connect)

    def request(req, body = nil, &block)
      protocol = use_ssl? ? 'https' : 'http'
      request_tracker = ::Nsa::NetHttpTracker.new(
        protocol, @address, @port, req.path, req.method, Hash[req.each_header.to_a]
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

      request_tracker.set_response_info(
        response.code, response.message, Hash[response.each_header.to_a]
      )
      request_tracker.response_body = body
      response
    end
  end
end
