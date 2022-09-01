RSpec.shared_context 'b2b service easy_entity_activity' do

  def sales_activity_sample(params = {})
    # Replace ':' to '=>'

    sample = {
      'id' => 60,
      'is_finished' => false,
      'all_day' => false,
      'start_time' => '2022-04-07T07:35:00Z',
      'end_time' => '2022-04-07T07:50:00Z',
      'created_at' => '2022-04-07T07:37:02Z',
      'updated_at' => '2022-04-07T07:37:02Z',
      'description' => '',
      'editable' => true,
      'entity' => {
        'id' => params[:with_entity].id,
        'type' => params[:with_entity].class.to_s,
        'name' => params[:with_entity].name
      }
    }

    add_user_attributes(sample, params[:with_users]) if params[:with_users]
    add_default_user(sample, params[:with_default_user]) if params[:with_default_user]

    add_entities(sample, 'contact_attendees', params[:with_contact_attendees]) if params[:with_contact_attendees]
    add_entities(sample, 'users_attendees', params[:with_users_attendees]) if params[:with_users_attendees]
    # enumerations
    add_entity(sample, 'category', params[:with_category]) if params[:with_category]

    sample
  end
end
