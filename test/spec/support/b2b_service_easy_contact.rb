RSpec.shared_context 'b2b service easy_contact' do

  def contact_sample(params = {})
    # Replace ':' to '=>'

    sample = {
      'id' => 1000,
      'author_note' => '<p>Test</p>',
      'firstname' => 'Test',
      'account_opened' => '2010-02-09',
      'account_closed' => '2010-02-10',
      'website' => 'https://test.ep.com',
      'is_global' => true,
      'referencable' => false,
      'easy_contact_type' => {
        'id' => params[:contact_type].id,
        'name' => params[:contact_type].name
      },
      'custom_fields' => [],
      'tag_list' => [
              'dev'
            ],
      'eu_member' => false,
      'guid' => '11daf11f-1e11-1b11-bfb1-f11e111111b1',
      'fullname' => 'Test',
      'account_duration' => 2,
      'expected_revenues_this_year' => '0.0',
      'last_year_revenues' => '0.0',
      'lifetime_revenues' => '0.0',
      'created_on' => '2020-02-09T14:06:41Z',
      'updated_on' => '2020-02-15T10:42:44Z'
    }

    add_time_zone(sample, params[:with_time_zone]) if params[:with_time_zone]
    add_user_attributes(sample, params[:with_users]) if params[:with_users]
    add_default_user(sample, params[:with_default_user]) if params[:with_default_user]
    add_billing_attributes(sample, params[:same_billing_attr])
    add_entity(sample, 'parent', params[:with_parent]) if params[:with_parent]
    add_custom_fields(sample, params[:with_cfs]) if params[:with_cfs]
    add_enumerations(sample, params[:with_enums]) if params[:with_enums]

    sample
  end

  def add_time_zone(sample, field_type)
    if field_type == :string
      sample['time_zone'] = 'Arizona'
    else
      sample['time_zone'] = {
        'name' => 'Arizona',
        'utc_offset' => nil,
        'tzinfo' => {
          'info' => {
            'identifier' => 'America/Phoenix',
          }
        }
      }
    end

  end

  def primary_billing_attr_response
    {
      'organization' => 'Primary test company',
      'street' => 'Primary test street',
      'city' => 'Primary test city',
      'country_code' => 'AU',
      'subdivision_code' => 'WA',
      'postal_code' => 'Primary test zip',
      'registration_no' => '123',
      'vat_no' => '123',
      'vat_rate' => '0.0',
      'email' => 'primary_test@email.com',
      'telephone' => '1234567890',
      'bank_account' => 'PrimaryTest123',
      'iban' => '123',
      'variable_symbol' => '.',
      'swift' => 'PrimaryTest123',
      'bic' => '123'
    }
  end

  def contact_billing_attr_response
    {
      'organization' => 'Test company',
      'street' => 'Test street',
      'city' => 'Test city',
      'country_code' => 'RU',
      'subdivision_code' => '',
      'postal_code' => 'test zip',
      'registration_no' => '456',
      'vat_no' => '456',
      'vat_rate' => '1.0',
      'email' => 'test@email.com',
      'telephone' => '9087654321',
      'bank_account' => 'Test123',
      'iban' => '456',
      'variable_symbol' => ',',
      'swift' => 'Test123',
      'bic' => '456',
    }
  end

  def add_billing_attributes(sample, same_billing_attr)
    if same_billing_attr
      billing_attributes = { 'billing_info' => primary_billing_attr_response }.merge(primary_billing_attr_response)
    else
      billing_attributes = { 'billing_info' => primary_billing_attr_response }.merge(contact_billing_attr_response)
    end
    billing_attributes['billing_info']['id'] = 1001

    sample.merge!(billing_attributes)

    sample
  end

  def returned_parent(id)
    FactoryBot.create(:easy_contact, b2b_external_id: id)
  end
end
