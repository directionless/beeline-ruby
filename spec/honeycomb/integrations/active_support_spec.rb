# frozen_string_literal: true

if defined?(Honeycomb::ActiveSupport)
  RSpec.describe Honeycomb::ActiveSupport do
    describe "custom notifications" do
      let(:libhoney_client) { Libhoney::TestClient.new }
      let(:configuration) do
        Honeycomb::Configuration.new.tap do |config|
          config.client = libhoney_client
        end
      end
      let(:client) { Honeycomb::Client.new(configuration: configuration) }
      let(:event_data) { libhoney_client.events.map(&:data) }
      let(:subscriber) do
        Honeycomb::ActiveSupport::Subscriber.new(client: client)
      end
      let(:event_name) { "honeycomb.test_event" }

      before do
        subscriber.subscribe(event_name) do |_name, span, payload|
          payload.each do |key, value|
            span.add_field(key, value)
          end
        end

        ActiveSupport::Notifications.instrument event_name, "honeycomb" => 1 do
        end
      end

      it_behaves_like "event data", package_fields: false, additional_fields: [
        "honeycomb",
      ]

      it "sends a single event" do
        expect(libhoney_client.events.size).to eq 1
      end
    end

    describe "custom notifications with custom hook" do
      let(:libhoney_client) { Libhoney::TestClient.new }
      let(:configuration) do
        Honeycomb::Configuration.new.tap do |config|
          config.client = libhoney_client
          config.notification_events = [event_name]
          config.on_notification_event do |_name, span, _payload|
            span.add_field("off_the_hook", "bees")
          end
        end
      end
      let!(:client) { Honeycomb::Client.new(configuration: configuration) }
      let(:event_data) { libhoney_client.events.map(&:data) }
      let(:event_name) { "honeycomb.test_event" }

      before do
        ActiveSupport::Notifications.instrument event_name, "honeycomb" => 1 do
        end
      end

      it_behaves_like "event data", package_fields: false, additional_fields: [
        "off_the_hook",
      ]

      it "sends a single event" do
        expect(libhoney_client.events.size).to eq 1
      end
    end
  end
end
