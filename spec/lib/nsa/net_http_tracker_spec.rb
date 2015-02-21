require 'spec_helper'
require 'open-uri'
require_relative '../../support/test_server'

describe Nsa::NetHttpTracker do
  describe '.new' do
    it 'notifies the on request handler' do
      notified_request_tracker = nil
      described_class.on_request { |request_tracker|
        notified_request_tracker = request_tracker
      }
      subject = described_class.new(
        'http', 'example.com', 80, '/', 'POST', {'header' => 'value' }, 'body'
      )

      expect(notified_request_tracker).to be(subject)
    end
  end

  describe 'tracking requests' do
    let(:base_url) { "http://localhost:#{port}" }
    let(:port) { TestServer.port }

    before(:all) do
      TestServer.boot
    end

    after(:all) do
      TestServer.stop
    end

    it 'tracks GET requests made with open-uri' do
      described_class.on_request { |request_tracker|
        expect(request_tracker.url).to eql("http://localhost/get_success")
        expect(request_tracker.port).to eql(port)
        expect(request_tracker.request_headers).to eql(
          'accept' => '*/*',
          'accept-encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'user-agent' => 'Ruby'
        )
        expect(request_tracker.response_body).to be(nil)

        request_tracker.on_response {
          expect(request_tracker.status_code).to eql("200")
          expect(request_tracker.status_message).to eql("OK")
          expect(request_tracker.response_headers).to eql(
            'connection' => 'close',
            'content-type' => 'text/plain',
            'server' => 'thin'
          )
        }

        request_tracker.on_body {
          expect(request_tracker.response_body).to eql('success')
        }
      }

      response = open("#{base_url}/get_success")
      expect(response.read).to eql("success")
    end

  end
end
