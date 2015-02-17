require 'net/http'
require 'json'
require_relative './ruby_inspector/nsa/net_http_tracker'

module RubyInspector
  class << self
    def enable
      connect
      send_info(
        method: "RubyInspector.initialize",
        params:{
          name: "My app",
          type: :ruby,
          description: "opens uris like a boss"
        }
      )

      ::Nsa::NetHttpTracker.on_request do |net_http_request_tracker|
        DevToolsRequestTracker.new(net_http_request_tracker)
      end
    end

    def send_info(data)
      socket.puts(
        ::JSON.generate(data)
      )
    end

    private

    attr_accessor :current_request_tracker, :socket
    def connect
      @socket = TCPSocket.new 'localhost', 8124

    end
  end

  class DevToolsRequestTracker

    def self.next_request_id
      @current_request_id ||= 0
      @current_request_id += 1
    end

    attr_reader :request_id, :request_tracker

    def initialize(request_tracker)
      @request_tracker = request_tracker
      @request_id = self.class.next_request_id.to_s
      notify_request_started
      request_tracker.on_response {
        notify_response_received
      }
      request_tracker.on_body {
        notify_body_received
      }
    end

    def notify_request_started
      RubyInspector.send_info(
        method: "Network.requestWillBeSent",
        params: {
          requestId: request_id,
          request: {
            url: request_tracker.url,
            method: request_tracker.method,
            headers: request_tracker.request_headers
          },
          timestamp: Time.now.to_f,
          type: "Other"
        }
      )
    end

    def notify_response_received
      RubyInspector.send_info(
        method: "Network.responseReceived",
        params:{
          requestId: request_id,
          timestamp: Time.now.to_f,
          type:"Document",
          response:{
            url: request_tracker.url,
            status: request_tracker.status_code,
            statusText: request_tracker.status_message,
            headers: request_tracker.response_headers,
            mimeType: "text/html",
            requestHeaders: request_tracker.request_headers,
            remotePort: request_tracker.port,
          }
        }
      )
    end

    def notify_body_received
      RubyInspector.send_info(
        method: "RubyInspector.network.cacheBody",
        params: { requestId: request_id },
        result: {
          body: request_tracker.response_body,
          base64Encoded: false
        }
      )

      sleep 2

      RubyInspector.send_info(
        method: "Network.loadingFinished",
        params: {
          requestId: request_id,
          timestamp: Time.now.to_f,
          encodedDataLength: request_tracker.response_body.length
        }
      )
    end
  end
end
