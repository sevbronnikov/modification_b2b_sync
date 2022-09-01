module ModificationB2bSync
  module UpdateData
    class EasyLead < ::ModificationB2bSync::UpdateData::Base
      SIMPLE_ATTRIBUTES = %w[company_name first_name last_name value email score source description telephone
                             mobile_phone job_title website disqualification_reason archived is_processed mautic_id
                             utm_source utm_medium utm_campaign utm_content utm_referrer utm_url referer affiliate
                             submission_form_identifier source_form lobby_identifier country_code].freeze
      RELATED_ATTRIBUTES = %w[easy_crm_case easy_contact easy_partner easy_personal_contact easy_campaign].freeze
      USER_ATTRIBUTES = %w[author assigned_to original_assigned_to external_assigned_to].freeze
      REQUIRED_USER_ATTRIBUTES = %w[author].freeze
      ENUM_ATTRIBUTES = %w[easy_lead_status easy_lead_source easy_lead_priority easy_product_solution
                           easy_price_book_quote_brand].freeze
      DATA_TYPE = 'easy_lead'.freeze

      private

      def update_entity
        update_simple_attributes
        update_related_attributes(without: ['easy_campaign'])
        update_user_attributes

        update_campaign_attribute

        update_enum
        update_cf

        entity
      end

      def update_campaign_attribute
        entity.easy_campaign = find_attribute_entity('easy_campaign', data['easy_campaign'])
        entity.easy_campaign_id ||= default_campaign_id
      end

    end
  end
end
