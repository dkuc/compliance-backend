# frozen_string_literal: true

# Common Kafka producer client
# https://www.rubydoc.info/gems/ruby-kafka/Kafka/Producer
class ApplicationProducer < Kafka::Client
  BROKERS = Settings.kafka.brokers.split(',').freeze
  CLIENT_ID = 'compliance-backend'
  SERVICE = 'compliance'
  DATE_FORMAT = :iso8601
  # Define TOPIC in the inherited class.
  # Example:
  #   TOPIC = 'platform.payload-status'

  class << self
    private

    def deliver_message(msg)
      msg = msg.merge(
        date: DateTime.now.utc.send(self::DATE_FORMAT),
        service: SERVICE,
        source: ENV['APPLICATION_TYPE']
      )
      kafka&.deliver_message(msg.to_json, topic: self::TOPIC)
    end

    def logger
      Rails.logger
    end

    def kafka_ca_cert
      return unless %w[ssl sasl_ssl].include?(Settings.kafka.security_protocol.downcase)

      File.read(Settings.kafka.ssl_ca_location) if Settings.kafka.ssl_ca_location
    end

    def sasl_config
      return unless Settings.kafka.security_protocol.downcase == 'sasl_ssl'

      config = {
        sasl_prefix(:username) => Settings.kafka.sasl_username,
        sasl_prefix(:password) => Settings.kafka.sasl_password,
        :ssl_ca_certs_from_system => true
      }

      return config if Settings.kafka.sasl_mechanism == 'PLAIN'

      config.merge(sasl_scram_mechanism: Settings.kafka.sasl_mechanism.try(:sub, /^SCRAM-SHA-/, 'sha'))
    end

    def kafka_config
      {}.tap do |config|
        config[:client_id] = self::CLIENT_ID
        config[:ssl_ca_cert] = kafka_ca_cert if kafka_ca_cert

        config.merge!(sasl_config) if sasl_config
      end
    end

    def kafka
      @kafka ||= Kafka.new(self::BROKERS, **kafka_config) if self::BROKERS.any?
    end

    def sasl_prefix(key)
      if Settings.kafka.sasl_mechanism == 'PLAIN'
        "sasl_plain_#{key}".to_sym
      else
        "sasl_scram_#{key}".to_sym
      end
    end
  end
end
