require "ruby_inspector/version"
require "json"
require_relative "./nsa/net_http_tracker"
require_relative "./ruby_inspector/dev_tools_request_tracker"

module RubyInspector
  DELIMITER = "\0"
  class << self
    def enable(app_name, description)
      @app_name = app_name
      @description = description

      begin
        send_init_info
      rescue Errno::ECONNREFUSED
        puts "[RubyInspector] Unable to send initialization info during setup"
      end

      ::Nsa::NetHttpTracker.on_request do |net_http_request_tracker|
        DevToolsRequestTracker.new(net_http_request_tracker)
      end
    end

    def disable
      @socket = nil
      @initialized = nil
    end

    def send_info(data)
      begin
        send_init_info unless initialized?
        send_socket_msg(data)
      rescue Errno::ECONNREFUSED
        puts "[RubyInspector] Unable to send data: #{data}"
      end
    end

    private

    attr_accessor :app_name, :description

    def initialized?
      @initialized
    end

    def socket
      @socket ||= TCPSocket.new("localhost", 8124)
    end

    def send_socket_msg(data)
      socket.puts(
        ::JSON.generate(data) + DELIMITER
      )
    end

    def send_init_info
      send_socket_msg(
        method: "RubyInspector.initialize",
        params: {
          name: app_name,
          type: :ruby,
          description: description
        }
      )
      @initialized = true
    end
  end
end
