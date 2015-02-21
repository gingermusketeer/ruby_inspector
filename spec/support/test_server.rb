require 'rubygems'
require 'rack'

class TestServer
  class<<self
    attr_reader :port

    def boot
      @port = find_available_port
      @server_thread ||= Thread.new do
        Rack::Handler::Thin.run(
          new, :Port => @port
        )
      end
      sleep 1
    end

    def stop
      @server_thread.join(0.1)
      @server_thread = nil
    end

    private

    def find_available_port
      server = TCPServer.new('127.0.0.1', 0)
      server.addr[1]
    ensure
      server.close if server
    end

  end

  def call(env)
    @root = File.expand_path(File.dirname(__FILE__))
    path = Rack::Utils.unescape(env['PATH_INFO'])
    case path
    when '/get_success'
      [ 200, {'Content-Type' => 'text/plain'}, 'success' ]
    else
      [ 404, {'Content-Type' => 'text/plain'}, '404 aw snap' ]
    end

  end
end
