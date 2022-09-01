module ModificationB2bSync
  module UpdateData
    class EasyPersonalContact < ::ModificationB2bSync::UpdateData::Base
      # standalone attributes: [account partner]
      SIMPLE_ATTRIBUTES = %w[first_name last_name middle_name first_name_phonetic last_name_phonetic previous_last_name
                             nick_name prefix_name suffix_name communication_language email telephone landline
                             instant_message latitude longitude organization job_title street city region subregion
                             postal_code time_zone internal_name non_deletable non_editable private description].freeze
      RELATED_ATTRIBUTES = %w[easy_personal_contact_type].freeze
      # account_manager= method missing
      USER_ATTRIBUTES = %w[author].freeze
      LOCATION_CODES_ATTRIBUTES = %w[subdivision country].freeze
      DATA_TYPE = 'easy_personal_contact'.freeze

      private

      def update_entity
        update_simple_attributes
        update_related_attributes
        update_account_or_partner_attribute
        update_location_codes_attributes
        update_user_attributes

        update_cf

        entity
      end

      def update_account_or_partner_attribute
        entity.account = find_attribute_entity('easy_contact', data['easy_contact'])
        # ------------------------------------------------
        # Adding easy_partner is not included in the task.
        # b2b_external_id not added to easy_partner.
        # ------------------------------------------------
        # entity.partner = find_attribute_entity('easy_partner', data['easy_partner'])
      end

      def update_location_codes_attributes
        self.class::LOCATION_CODES_ATTRIBUTES.each do |name|
          if data[name]
            entity.send("#{name}_code=", data[name]['code'])
          else
            entity.send("#{name}_code=", nil)
          end
        end
      end

    end
  end
end
