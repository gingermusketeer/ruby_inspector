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
      :request_body, :status_code, :status_message, :response_headers,
      :response_body

    def initialize(protocol, address, port, path, method, headers, body)
      @protocol = protocol
      @address = address
      @port = port
      @path = path
      @method = method
      @request_headers = headers
      @request_body = body
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
      on_response.call
    end

    def response_body=(body)
      @response_body = body
      on_body.call
    end
  end
end

module Net
  class HTTP
    alias_method(:orig_request, :request) unless method_defined?(:orig_request)
    alias_method(:orig_connect, :connect) unless method_defined?(:orig_connect)

    def request(req, request_body = nil, &block)
      return orig_request(req, request_body, &block) unless started?
      protocol = use_ssl? ? 'https' : 'http'
      request_headers = Hash[req.each_header.to_a]
      request_tracker = ::Nsa::NetHttpTracker.new(
        protocol, @address, @port, req.path, req.method, request_headers,
        request_body || req.body
      )

      response_body = ''
      block_provided = block_given?
      response = orig_request(req, request_body) do |resp|
        resp.read_body { |str| response_body << str }
        resp.define_singleton_method(:read_body) do |dest = nil, &block|
          dest << response_body unless dest.nil?
          block.call(response_body) unless block.nil?
          response_body
        end
        block.call(resp) if block_provided
      end

      request_tracker.set_response_info(
        response.code, response.message, Hash[response.each_header.to_a]
      )
      request_tracker.response_body = response_body
      response
    end
  end
end
