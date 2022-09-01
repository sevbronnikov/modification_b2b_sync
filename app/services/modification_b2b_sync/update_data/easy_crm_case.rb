module ModificationB2bSync
  module UpdateData
    class EasyCrmCase < ::ModificationB2bSync::UpdateData::Base
      # standalone attributes: [account easy_crm_case_status project]
      # accounted_by_id - Partner
      SIMPLE_ATTRIBUTES = %w[name description contract_date email telephone price is_repeated currency need_reaction
                             next_action is_canceled is_finished email_cc paid_on lock_version all_day closed_on
                             lead_value probability price_EUR price_USD case_probability adjusted_value locked locked_at
                             unlocked_at affiliate_uuid sale_type tag_list guid].freeze
      USER_ATTRIBUTES = %w[author assigned_to easy_closed_by easy_last_updated_by external_assigned_to].freeze
      REQUIRED_USER_ATTRIBUTES = %w[author].freeze
      # EasyCrmCaseBrand don't define (ENUMERATION)
      ENUM_ATTRIBUTES = %w[easy_price_book_quote_brand easy_crm_case_payment_method].freeze
      DATA_TYPE = 'easy_crm_case'.freeze

      private

      def update_entity
        update_simple_attributes
        update_user_attributes
        update_account_attribute
        # update_accounted_by_id_attribute # no logic for partner
        update_easy_crm_case_status_attribute
        update_project_attribute

        update_enum
        update_cf

        entity
      end

      def update_account_attribute
        # main_easy_contact, customer
        entity.main_easy_contact = find_attribute_entity('easy_contact', data['account'])
      end

      def update_accounted_by_id_attribute
        # easy_partner
        entity.accounted_by = find_attribute_entity('easy_partner', data['accounted_by'])
      end

      def update_easy_crm_case_status_attribute
        entity.easy_crm_case_status = find_attribute_entity('easy_crm_case_status', data['easy_crm_case_status'])
      end

      def update_project_attribute
        entity.project = find_attribute_entity('project', data['project'])
        entity.project_id ||= default_project_id
      end

    end
  end
end
