module ModificationB2bSync
  module UpdateData
    class EasyEntityActivity < ::ModificationB2bSync::UpdateData::Base
      # standalone attributes: [entity users_attendees contact_attendees]
      SIMPLE_ATTRIBUTES = %w[is_finished all_day start_time end_time description].freeze
      USER_ATTRIBUTES = %w[author].freeze
      # easy_entity_activity_category is a category
      ENUM_ATTRIBUTES = %w[easy_entity_activity_category].freeze
      DATA_TYPE = 'easy_entity_activity'.freeze

      private

      def update_entity
        update_simple_attributes
        update_user_attributes

        update_entity_attribute
        update_users_attendees_attribute
        update_contact_attendees_attribute

        update_enum
        update_cf

        entity
      end

      def update_entity_attribute
        return entity.entity = nil unless data['entity']

        entity.entity = case data['entity']['type']
                        when 'EasyCrmCase'
                          find_attribute_entity('easy_crm_case', data['entity'])
                        when 'EasyLead'
                          find_attribute_entity('easy_lead', data['entity'])
                        else
                          nil
                        end
      end

      def update_users_attendees_attribute
        return if data['users_attendees'].blank?

        user_ids = data['users_attendees'].map do |ua|
          user = User.find_by(b2b_external_id: ua['id'])
          user&.id || default_user_id
        end

        entity.easy_entity_activity_user_ids = user_ids
      end

      def update_contact_attendees_attribute
        return if data['contact_attendees'].blank?

        activity_contacts = ::EasyContact.where(b2b_external_id: data['contact_attendees'].map { |ca| ca['id'] })
        entity.easy_entity_activity_contacts = activity_contacts
      end

      def update_enum
        entity.category = ::EasyEntityActivityCategory.find_by(b2b_external_id: data['category']['id'].to_s) if data['category']
      end

    end
  end
end
