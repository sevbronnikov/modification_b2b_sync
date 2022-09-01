RSpec.shared_context 'b2b service easy_crm_case' do

  def crm_case_sample(params = {})
    # Replace ':' to '=>'

    sample = {
      'id' => 4,
      'name' => 'Test',
      'easy_crm_case_status' => {
        'id' => params[:crm_case_status].id,
        'name' => params[:crm_case_status].name,
        'internal_name' => params[:crm_case_status].name.downcase,
        'position' => 1,
        'is_default' => true,
        'is_easy_contact_required' => params[:crm_case_status].is_easy_contact_required, # Check!
        'is_closed' => false,
        'is_won' => false,
        'is_paid' => false,
        'is_provisioned' => false,
        'created_at' => '2016-11-29T14:33:08Z',
        'updated_at' => '2016-11-29T14:33:08Z'
      },
      'project' => {
        'id' => params[:project].id,
        'name' => params[:project].name
      },
      'description' => '<p>Test description</p>',
      'contract_date' => '2022-03-01',
      'email' => 'test@email.com',
      'telephone' => '+49999999999',
      'price' => '200.0',
      'is_repeated' => false,
      'currency' => 'USD',
      'need_reaction' => false,
      'next_action' => '2022-03-31',
      'is_canceled' => false,
      'is_finished' => false,
      'email_cc' => 'test_email_cc@email.com',
    }

    add_user_attributes(sample, params[:with_users]) if params[:with_users]
    add_default_user(sample, params[:with_default_user]) if params[:with_default_user]
    add_entity(sample, 'account', params[:with_account]) if params[:with_account]
    add_custom_fields(sample, params[:with_cfs]) if params[:with_cfs]
    add_enumerations(sample, params[:with_enums]) if params[:with_enums]

    sample
  end
end
