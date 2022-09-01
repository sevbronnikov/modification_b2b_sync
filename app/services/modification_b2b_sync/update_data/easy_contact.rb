module ModificationB2bSync
  module UpdateData
    class EasyContact < ::ModificationB2bSync::UpdateData::Base
      # standalone attributes: [time_zone parent]
      SIMPLE_ATTRIBUTES = %w[firstname lastname latitude longitude expected_revenues_this_year
                             last_year_revenues lifetime_revenues account_opened account_closed website
                             referencable tag_list is_global author_note eu_member score account_duration].freeze
      RELATED_ATTRIBUTES = %w[easy_contact_type].freeze
      USER_ATTRIBUTES = %w[author assigned_to external_assigned_to].freeze
      PRIMARY_BILLING_ATTRIBUTES = %w[organization street city country_code subdivision_code postal_code
                                      registration_no vat_no vat_rate email telephone bank_account iban
                                      variable_symbol swift bic].freeze
      ENUM_ATTRIBUTES = %w[easy_contact_status easy_contact_level easy_contact_customer_left_reason
                           easy_contact_industry easy_supplier_company].freeze
      DATA_TYPE = 'easy_contact'.freeze

      private

      # ---------------Missing in JSON----------------
      # easy_contact_group_ids    - Missing JSON request
      # easy_contact_references   -

      def update_entity
        update_simple_attributes
        update_time_zone_attribute
        update_related_attributes
        update_parent_attribute
        update_user_attributes
        update_easy_billing_infos

        update_enum
        update_cf

        entity
      end

      def update_easy_billing_infos
        return if data['billing_info'].blank?

        if use_as_contact?
          set_billing_attributes({ primary: true, contact: true })
        else
          set_billing_attributes({ primary: true, contact: false })
          set_billing_attributes({ primary: false, contact: true })
        end
      end

      def set_billing_attributes(flags = {})
        # ---------------------------------------------------------------------------------------
        # primary_billing_attributes and contact_billing_attributes can have the same attributes.
        # It is correct to use only primary_billing_attributes.
        # ---------------------------------------------------------------------------------------
        attrs_type = flags[:primary] ? 'primary' : 'contact'
        sub_data = flags[:primary] ? data['billing_info'] : data

        entity.send("#{attrs_type}_easy_billing_info_attributes=", self.class::PRIMARY_BILLING_ATTRIBUTES.each_with_object({ primary: flags[:primary], contact: flags[:contact] }) { |name, obj| obj[name] = sub_data[name] })
      end

      def use_as_contact?
        # ---------------------------------------------------------------------------------------
        # If all attributes are equal, then only primary_billing_attributes are used.
        # See the checkbox on the "/easy_contacts/?/edit"
        # ---------------------------------------------------------------------------------------
        self.class::PRIMARY_BILLING_ATTRIBUTES.none? { |name| data['billing_info'][name] != data[name] }
      end

      def update_time_zone_attribute
        if data['time_zone'].is_a?(Hash)
          entity.send('time_zone=', data['time_zone']['name'])
        elsif data['time_zone'].is_a?(String)
          entity.send('time_zone=', data['time_zone'])
        else
          entity.send('time_zone=', nil)
        end
      end

      def update_parent_attribute
        entity.send('parent=', find_parent)
      end

      def find_parent
        return nil unless data['parent']

        entity_type.find_by(b2b_external_id: data['parent']['id']) || get_parent(data['parent']['id'])
      end

      def get_parent(b2b_external_id)
        parent_data = client.get(data_type, b2b_external_id)[data_type]
        self.class.call(parent_data).entity
      end

    end
  end
end
