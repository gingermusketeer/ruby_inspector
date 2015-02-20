require 'ruby_inspector/version'

require 'json'
require_relative './nsa/net_http_tracker'
require_relative './ruby_inspector/dev_tools_request_tracker'

module RubyInspector
  class << self
    def enable(app_name, description = '')
      connect
      send_init_info(app_name, description)

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

    attr_accessor :socket
    def connect
      @socket = TCPSocket.new 'localhost', 8124
    end

    def send_init_info(app_name, description)
      send_info(
        method: 'RubyInspector.initialize',
        params: {
          name: app_name,
          type: :ruby,
          description: description
        }
      )
    end
  end
end
