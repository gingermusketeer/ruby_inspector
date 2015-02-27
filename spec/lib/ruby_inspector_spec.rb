require "spec_helper"

describe RubyInspector do
  it "has a version number" do
    expect(RubyInspector::VERSION).not_to be nil
  end

  describe ".enable" do
    let(:socket) { double("socket") }
    let(:init_message) do
      '{"method":"RubyInspector.initialize","params":{"name":"test app",'\
      '"type":"ruby","description":"test app desc"}}' + "\0"
    end

    before do
      described_class.disable
    end

    context "when the server is running" do
      it "sends an initialization message to the ruby inspector server" do
        allow(TCPSocket).to receive(:new).with("localhost", 8124).and_return(
          socket
        )
        expect(socket).to receive(:puts).with(init_message)
        described_class.enable("test app", "test app desc")
      end
    end

    context "when the server is not running" do
      let(:other_message) { %({"method":"testing"}\0) }

      before do
        allow(TCPSocket).to receive(:new).with("localhost", 8124).and_raise(
          Errno::ECONNREFUSED
        )
      end

      it "catches the exception" do
        expect(socket).not_to receive(:puts)
        expect {
          described_class.enable("test app", "test app desc")
        }.not_to raise_error
      end

      it "resends the init message when more info is sent" do
        # fails first time
        described_class.enable("test app", "test app desc")

        allow(TCPSocket).to receive(:new).with("localhost", 8124).and_return(
          socket
        )
        expect(socket).to receive(:puts).with(init_message)
        expect(socket).to receive(:puts).with(other_message)

        described_class.send_info(method: "testing")
      end
    end
  end
end
