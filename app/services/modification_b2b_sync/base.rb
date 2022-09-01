module ModificationB2bSync
  class Base
    LIMIT = ::ModificationB2bSync::Client::LIMIT

    def self.call(*args, &block)
      new(*args, &block).call
    end

    attr_reader :attributes

    def initialize(attributes = {})
      @attributes = attributes
    end

    private

    def client
      @client ||= ::ModificationB2bSync::Client.new
    end

    def limit
      @limit ||= client.class::LIMIT
    end

    def data_types
      raise NotImplementedError
    end

    def entity_type
      raise NotImplementedError
    end

    def log_info(message)
      ::EasyRakeTaskB2bSynchronizing.log_b2b_info(message)
    end

  end
end
