RSpec.shared_context 'b2b service easy_personal_contact' do

  def personal_contact_sample(params = {})
    # Replace ':' to '=>'

    sample = {
      'id' => 1000,
      'guid' => 'o111111o-1o1o-1oo1-1111-1oo1111111oo',
      'first_name' => 'John',
      'last_name' => 'Smith',
      'middle_name' => 'Arthur',
      'prefix_name' => 'Mr.',
      'communication_language' => 'de',
      'email' => 'ceo@example.com',
      'telephone' => '+4499999999',
      'instant_message' => 'Test instant message',
      'landline' => 'Test landline',
      'time_zone' => 'Brussels',
      'organization' => 'Test organization',
      'job_title' => 'TEST',
      'street' => 'Test street',
      'city' => 'Test city',
      'region' => 'Europe',
      'subregion' => 'Eastern Europe',
      'postal_code' => 'Example',
      'account_manager' => {
        'id' => 67,
        'name' => 'Bugs Bunny'
      },
      'external_account_manager' => {
        'id' => 67,
        'name' => 'Bugs Bunny'
      },
      'easy_personal_contact_type' => {
        'id' => params[:personal_contact_type].id,
        'name' => params[:personal_contact_type].name
      },
      'created_at' => '2021-01-01T13 =>07 =>30Z',
      'updated_at' => '2022-01-01T08 =>43 =>19Z'
    }

    add_location_codes_attributes(sample) if params[:with_location_codes]
    add_user_attributes(sample, params[:with_users]) if params[:with_users]
    add_default_user(sample, params[:with_default_user]) if params[:with_default_user]
    add_entity(sample, 'easy_contact', params[:with_easy_contact]) if params[:with_easy_contact]
    add_entity(sample, 'easy_partner', params[:with_easy_partner]) if params[:with_easy_partner]
    add_custom_fields(sample, params[:with_cfs]) if params[:with_cfs]

    sample
  end

  def add_location_codes_attributes(sample)
    location_codes_attributes = {
      'subdivision' => {
        'name' => 'Brno',
        'code' => '622'
      },
      'country' => {
        'name' => 'Чехия',
        'code' => 'CZ'
      }
    }

    sample.merge!(location_codes_attributes)
  end
end
