module Postal
  module MessageDB
    class Delivery
      def self.create(message, attributes = {})
        attributes = message.database.stringify_keys(attributes)
        attributes = attributes.merge('message_id' => message.id, 'timestamp' => Time.now.to_f)
        id = message.database.insert('deliveries', attributes)
        delivery = Delivery.new(message, attributes.merge('id' => id))
        delivery.update_statistics
        delivery.send_webhooks
        delivery
      end

      def initialize(message, attributes)
        @message = message
        @attributes = attributes.stringify_keys
      end

      def method_missing(name, _value = nil)
        @attributes[name.to_s] if @attributes.has_key?(name.to_s)
      end

      def timestamp
        @timestamp ||= @attributes['timestamp'] ? Time.zone.at(@attributes['timestamp']) : nil
      end

      def update_statistics
        @message.database.statistics.increment_all(timestamp, 'held') if status == 'Held'

        @message.database.statistics.increment_all(timestamp, 'bounces') if status == 'Bounced' || status == 'HardFail'
      end

      def send_webhooks
        WebhookRequest.trigger(@message.database.server_id, webhook_event, webhook_hash) if webhook_event
      end

      def webhook_hash
        {
          message: @message.webhook_hash,
          status: status,
          details: details,
          output: output.to_s.force_encoding('UTF-8').scrub,
          sent_with_ssl: sent_with_ssl,
          timestamp: @attributes['timestamp'],
          time: time
        }
      end

      def webhook_event
        @webhook_event ||= case status
                           when 'Sent' then 'MessageSent'
                           when 'SoftFail' then 'MessageDelayed'
                           when 'HardFail' then 'MessageDeliveryFailed'
                           when 'Held' then 'MessageHeld'
                           end
      end
    end
  end
end
