RSpec.shared_context 'b2b service easy_lead' do

  def lead_sample(params = {})
    # Replace ':' to '=>'

    sample = {
      'id' => 1200,
      'company_name' => 'TEst company',
      'first_name' => 'Test',
      'last_name' => 'TEst',
      'value' => 'Value',
      'email' => 'test@test.com',
      'score' => 1,
      'source' => '',
      'description' => '<p>Test</p>',
      'telephone' => '+499999999',
      'mobile_phone' => '+498888888',
      'job_title' => 'TEst',
      'country_code' => 'AL',
      'website' => 'test.com',
      'disqualification_reason' => '',
      'archived' => false,
      'is_processed' => params[:is_processed],
      'mautic_id' => '',
      'utm_source' => '',
      'utm_medium' => '',
      'utm_campaign' => '',
      'utm_content' => '',
      'utm_referrer' => '',
      'utm_url' => '',
      'name' => 'Test TEst from TEst company',
      'referer' => '',
      'affiliate' => '',
      'submission_form_identifier' => '',
      'source_form' => '',
      'lobby_identifier' => '',
      'created_at' => '2022-03-20T17:47:34Z',
      'updated_at' => '2022-03-20T17:49:02Z'
      }

    add_user_attributes(sample, params[:with_users]) if params[:with_users]
    add_default_user(sample, params[:with_default_user]) if params[:with_default_user]

    if params[:with_related_attributes]
      %i[external_account external_personal_contact external_crm_case external_campaign].each do |entity|
        next unless params[:with_related_attributes][entity]

        add_entity(sample, params[:with_related_attributes][entity])
      end
    end

    add_custom_fields(sample, params[:with_cfs]) if params[:with_cfs]
    add_enumerations(sample, params[:with_enums]) if params[:with_enums]

    sample
  end
end
