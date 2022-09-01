module ModificationB2bSync
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_enumerations_form_bottom, partial: 'enumerations/b2b_external_id_field'
    render_on :view_custom_fields_form_right_content, partial: 'custom_fields/b2b_external_id_field'
    render_on :view_projects_form, partial: 'projects/b2b_external_id_field'
    render_on :view_easy_personal_contact_types_form_additional_cf, partial: 'easy_personal_contact_types/b2b_external_id_field'
    render_on :view_easy_contact_type_header_bottom, partial: 'easy_contact_types/b2b_external_id_field'
    render_on :view_users_form_content_right, partial: 'users/b2b_external_id_field'

  end
end
