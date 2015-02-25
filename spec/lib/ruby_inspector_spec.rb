require 'spec_helper'

describe RubyInspector do
  it 'has a version number' do
    expect(RubyInspector::VERSION).not_to be nil
  end

  describe '.enable' do
    let(:socket) { double('socket') }

    before do
      allow(described_class).to receive(:socket).and_return(socket)
    end

    context "when the server is running" do
      let(:init_message) {
        %({"method":"RubyInspector.initialize","params":{"name":"test app","type":"ruby","description":"test app desc"}}\0)
      }

      it 'sends an initialization message to the ruby inspector server' do
        expect(described_class).to receive(:connect)

        expect(socket).to receive(:puts).with(init_message)
        described_class.enable('test app', 'test app desc')
      end
    end
  end
end
