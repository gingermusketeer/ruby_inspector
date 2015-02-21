require 'spec_helper'

describe RubyInspector do
  it 'has a version number' do
    expect(RubyInspector::VERSION).not_to be nil
  end

  describe '.enable' do
    it 'sends an initialization message to the ruby inspector server' do
      allow(described_class).to receive(:connect)
      expect(described_class).to receive(:send_info).with(
        method: 'RubyInspector.initialize',
        params: {
          name: 'test app',
          type: :ruby,
          description: 'test app description'
        }
      )
      described_class.enable('test app', 'test app description')
    end
  end

  describe '.send_info' do
    let(:fake_socket) { double('fake_socket') }
    it 'serializes the info and appends a null byte delimiter' do
      allow(described_class).to receive(:socket).and_return(fake_socket)
      expect(fake_socket).to receive(:puts).with(
        %({"name":"test"}\0)
      )

      described_class.send_info(name: 'test')
    end
  end
end
