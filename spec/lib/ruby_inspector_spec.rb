require "spec_helper"

describe RubyInspector do
  let(:socket) { double("socket") }
  let(:init_message) do
    '{"method":"RubyInspector.initialize","params":{"name":"test app",'\
    '"type":"ruby","description":"test app desc"}}' + "\0"
  end

  let(:app_name) { "test app" }
  let(:description) { "test app desc" }

  it "has a version number" do
    expect(RubyInspector::VERSION).not_to be nil
  end

  describe ".enable" do
    before do
      described_class.disable
    end

    context "when the server is running" do
      it "sends an initialization message to the ruby inspector server" do
        allow(TCPSocket).to receive(:new).with("localhost", 8124).and_return(
          socket
        )
        expect(socket).to receive(:puts).with(init_message)
        described_class.enable(app_name, description)
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
          described_class.enable(app_name, description)
        }.not_to raise_error
      end

      it "resends the init message when more info is sent" do
        # fails first time
        described_class.enable(app_name, description)

        allow(TCPSocket).to receive(:new).with("localhost", 8124).and_return(
          socket
        )
        expect(socket).to receive(:puts).with(init_message)
        expect(socket).to receive(:puts).with(other_message)

        described_class.send_info(method: "testing")
      end
    end
  end

  describe ".send_info" do
    let(:encoded_msg) { %({"key":"value"}\0) }
    let(:msg) { { key: "value" } }
    before do
      allow(described_class).to receive(:socket).and_return(socket)
    end

    it "sends delimited messages to the ruby inspector server" do
      expect(socket).to receive(:puts).with(encoded_msg)
      described_class.send_info(msg)
    end

    it "tries to repair broken pipes" do
      expect(socket).to receive(:puts).with(encoded_msg) {
        allow(described_class).to receive(:socket).and_call_original
        new_socket = double(:new_socket)
        allow(TCPSocket).to receive(:new).and_return(new_socket)
        allow(described_class).to receive(:app_name).and_return(app_name)
        allow(described_class).to receive(:description).and_return(description)

        # Reinitializes the connection to the server
        expect(new_socket).to receive(:puts).with(init_message)
        # Send the new info
        expect(new_socket).to receive(:puts).with(encoded_msg)
        fail Errno::EPIPE
      }
      described_class.send_info(msg)
    end
  end
end
