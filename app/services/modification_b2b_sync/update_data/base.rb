module ModificationB2bSync
  module UpdateData
    class Base < ::ModificationB2bSync::Base
      USER_LOG_INDENT = 25
      ENUM_ATTRIBUTES = [].freeze
      RELATED_ATTRIBUTES = [].freeze
      TYPES_ATTRIBUTES = [].freeze
      REQUIRED_USER_ATTRIBUTES = [].freeze

      attr_reader :data

      def initialize(data)
        @data = data
        @user_attributes_messages = []
      end

      def call
        update_entity
        response
      end

      private

      attr_accessor :user_attributes_messages

      def response
        if entity.save
          after_save_callback
          OpenStruct.new({ success?: true, entity: entity })
        else
          log_errors
          OpenStruct.new({ success?: false, errors: entity.errors })
        end
      end

      def after_save_callback
        status = entity.id_previously_changed? ? 'CREATED' : 'UPDATED'
        message = "#{status} -> id = #{entity.id}. #{data_type.pluralize.humanize(capitalize: false)}#{write_entity_name}#{users_message}"
        log_info(message)
      end

      def log_errors
        errors = entity.errors.full_messages.join(', ')
        new_record = entity.new_record? ? 'fail creating' : 'fail updating'
        message = "ERROR -> b2b_external_id = #{entity.b2b_external_id}. #{new_record}. #{errors}#{write_entity_name}.#{users_message}"
        log_info(message)
      end

      def entity
        @entity ||= entity_type.find_or_initialize_by(b2b_external_id: data['id'])
      end

      def data_type
        raise NotImplementedError unless self.class.const_defined?(:DATA_TYPE)

        @data_type ||= self.class.const_get(:DATA_TYPE)
      end

      def entity_type
        @entity_type ||= "::#{data_type.classify}".constantize
      end

      def entity_type_cf
        @entity_type_cf ||= "::#{data_type.classify}CustomField".constantize
      end

      def available_custom_fields
        @available_custom_fields ||= entity_type_cf.where.not(b2b_external_id: nil).each_with_object({}) { |cf, obj| obj[cf.b2b_external_id.to_i] = cf }
      end

      def update_simple_attributes
        self.class::SIMPLE_ATTRIBUTES.each do |name|
          next unless entity.respond_to?("#{name}=")

          entity.send("#{name}=", data[name]) if data[name]
        end
      end

      def update_related_attributes(without: [])
        self.class::RELATED_ATTRIBUTES.each do |name|
          next if without.include?(name)

          entity.send("#{name}=", find_attribute_entity(name, data[name]))
        end
      end

      def update_user_attributes
        self.class::USER_ATTRIBUTES.each do |name|
          entity.send("#{name}_id=", set_user_value(name))
        end
      end

      def set_user_value(name)
        if data[name]
          user = User.find_by(b2b_external_id: data[name]['id'])
          if user
            user_log(' ' * USER_LOG_INDENT + "USER -> id = #{user.id}, b2b_external_id = #{data[name]['id']}. #{name} found and imported")
            user.id
          else
            user_log(' ' * USER_LOG_INDENT + "USER -> b2b_external_id = #{data[name]['id']}. #{name} not found. Default user set.")
            default_user_id
          end
        else
          if self.class::REQUIRED_USER_ATTRIBUTES.include?(name)
            user_log(' ' * USER_LOG_INDENT + "USER -> Required #{name} is missing from response. Default user set.")
            default_user_id
          else
            user_log(' ' * USER_LOG_INDENT + "USER -> #{name} is missing from response. Nill set.")
            nil
          end
        end
      end

      def user_log(message)
        user_attributes_messages << message
      end

      def write_entity_name
        if entity.is_a?(::EasyEntityActivity)
          entity.entity ? "\nEntity name: #{entity&.entity&.name}" : nil
        else
          "\nname: #{entity&.name}"
        end
      end

      def users_message
        return nil if user_attributes_messages.blank?

        "\n#{user_attributes_messages.join("\n")}"
      end

      def update_cf
        return if data['custom_fields'].blank?

        cfv = {}
        data['custom_fields'].each do |cf|
          available_cf = available_custom_fields[cf['id']]
          next if available_cf.nil?

          cfv[available_cf.id] = cf['value']
        end

        entity.custom_field_values = cfv
      end

      def update_enum
        self.class::ENUM_ATTRIBUTES.each do |name|
          entity.send("#{name}=", find_attribute_entity(name, data[name]))
        end
      end

      def find_attribute_entity(entity_name, entity_data)
        return nil unless entity_data

        enum_class = "::#{entity_name.classify}".constantize
        enum_class.find_by(b2b_external_id: entity_data['id'].to_s)
      end

      def default_user_id
        return @default_user_id if @default_user_id

        log_info('WARNING -> Default User ID field must be filled in. Look at ".../easy_settings/modification_b2b_sync/edit"') if setting('default_user_id').blank?
        @default_user_id ||= setting('default_user_id').to_i
      end

      def default_project_id
        return @default_project_id if @default_project_id

        log_info('WARNING -> Default Project ID field must be filled in. Look at ".../easy_settings/modification_b2b_sync/edit"') if setting('default_project_id').blank?
        @default_project_id ||= setting('default_project_id').to_i
      end

      def default_campaign_id
        return @default_campaign_id if @default_campaign_id

        log_info('WARNING -> Default Campaign ID field must be filled in. Look at ".../easy_settings/modification_b2b_sync/edit"') if setting('default_campaign_id').blank?
        @default_campaign_id ||= setting('default_campaign_id').to_i
      end

      def setting(attr)
        ::EasySetting.value("modification_b2b_sync_#{attr}")
      end

    end
  end
end
