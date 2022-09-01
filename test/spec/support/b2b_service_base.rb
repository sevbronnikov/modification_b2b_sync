RSpec.shared_context 'b2b service base' do
  ATTRIBUTES_LISTS = %w[simple_attributes location_codes_attributes user_attributes types_attributes
                        related_attributes enum_attributes primary_billing_attributes].freeze

  ATTRIBUTES_LISTS.each do |name|
    define_method(name) { described_class.const_get(name.upcase) if described_class.const_defined?(name.upcase) }
  end

  def cf_types
    %w[string email country_select easy_computed_from_query bool list date]
  end

  def data_type
    described_class.const_get(:DATA_TYPE)
  end

  def custom_field_class_name
    return :"easy_b2b_#{data_type}_custom_field" if data_type == 'easy_personal_contact'

    :"#{data_type}_custom_field"
  end

  def create_external_custom_fields
    cf_types.map do |cf_type|
      options = { field_format: cf_type,
                  min_length: nil,
                  max_length: nil }
      options[:possible_values] = %w[Value1 Value2 Value3] if cf_type == 'list'
      FactoryBot.create(custom_field_class_name, options)
    end
  end

  def create_internal_custom_fields(cfs)
    cfs.map do |cf|
      options = { field_format: cf.field_format,
                  b2b_external_id: cf.id,
                  min_length: nil,
                  max_length: nil }
      options[:possible_values] = cf.possible_values if cf.field_format == 'list'
      FactoryBot.create(custom_field_class_name, options)
    end
  end

  def create_external_related_entities
    external_account_contact_type = FactoryBot.create(:easy_contact_type,
                                             type_name: 'Account',
                                             internal_name: 'account')
    external_account = FactoryBot.create(:easy_contact,
                                         easy_contact_type: external_account_contact_type)
    external_personal_contact_type = FactoryBot.create(:easy_personal_contact_type)
    external_personal_contact = FactoryBot.create(:easy_personal_contact,
                                                  easy_personal_contact_type: external_personal_contact_type,
                                                  account: external_account)
    external_crm_case_status = FactoryBot.create(:easy_crm_case_status,
                                                 is_easy_contact_required: true)
    external_project = FactoryBot.create(:project)
    external_crm_case = FactoryBot.create(:easy_crm_case,
                                          easy_crm_case_status: external_crm_case_status,
                                          main_easy_contact: external_account,
                                          project: external_project)
    external_lead = FactoryBot.create(:easy_lead)

    { external_account_contact_type: external_account_contact_type,
      external_account: external_account,
      external_personal_contact_type: external_personal_contact_type,
      external_personal_contact: external_personal_contact,
      external_crm_case_status: external_crm_case_status,
      external_project: external_project,
      external_crm_case: external_crm_case,
      external_lead: external_lead
    }
  end

  def create_internal_related_entities(e_entities)
    account_contact_type = FactoryBot.create(:easy_contact_type,
                                             type_name: 'Account',
                                             internal_name: 'account',
                                             b2b_external_id: e_entities[:external_account_contact_type].id)
    account = FactoryBot.create(:easy_contact,
                                easy_contact_type: account_contact_type,
                                b2b_external_id: e_entities[:external_account].id)
    personal_contact_type = FactoryBot.create(:easy_personal_contact_type,
                                              b2b_external_id: e_entities[:external_personal_contact_type].id)
    personal_contact = FactoryBot.create(:easy_personal_contact,
                                         easy_personal_contact_type: personal_contact_type,
                                         account: account,
                                         b2b_external_id: e_entities[:external_personal_contact].id)
    crm_case_status = FactoryBot.create(:easy_crm_case_status,
                                        is_easy_contact_required: true,
                                        b2b_external_id: e_entities[:external_crm_case_status].id)
    project = FactoryBot.create(:project,
                                b2b_external_id: e_entities[:external_project].id)
    crm_case = FactoryBot.create(:easy_crm_case,
                                 easy_crm_case_status: crm_case_status,
                                 main_easy_contact: account,
                                 project: project,
                                 b2b_external_id: e_entities[:external_crm_case].id)
    lead = FactoryBot.create(:easy_lead,
                             b2b_external_id: e_entities[:external_lead].id)

    [account, personal_contact, crm_case, lead]
  end

  def create_external_enumerations
    enum_attributes.map do |name|
      FactoryBot.create(:enumeration, type: name.classify, active: true)
    end
  end

  def create_internal_enumerations(enums)
    enums.map do |enum|
      FactoryBot.create(:enumeration, type: enum.type, active: true, b2b_external_id: enum.id)
    end
  end

  def create_external_users(other_names = nil)
    e_user_hash = {}
    names = other_names || user_attributes
    names.each do |name|
      e_user_hash[name] = FactoryBot.create(:user)
    end

    e_user_hash
  end

  def create_internal_users(e_user_hash, other_names = nil)
    i_user_hash = {}
    names = other_names || user_attributes
    names.each do |name|
      i_user_hash[name] = FactoryBot.create(:user, b2b_external_id: e_user_hash[name].id)
    end

    i_user_hash
  end

  def add_custom_fields(sample, e_cfs)
    i_cfs = e_cfs.map do |cf|
      cf_value = case cf.field_format
                 when 'string'
                   'String custom field'
                 when 'email'
                   'email@cf.com'
                 when 'country_select'
                   'AU'
                 when 'easy_computed_from_query'
                   '123'
                 when 'bool'
                   '1'
                 when 'list'
                   cf.possible_values.sample
                 when 'date'
                   '2022-02-09'
                 end

      {
        'id' => cf.id,
        'name' => cf.name,
        'internal_name' => cf.internal_name,
        'field_format' => cf.field_format,
        'value' => cf_value
      }
    end

    sample['custom_fields'] = i_cfs
    sample
  end

  def add_enumerations(sample, e_enums)
    i_enums = {}
    e_enums.map do |enum|
      i_enums[enum.type.tableize.singularize] = { 'id' => enum.id,
                                                  'name' => enum.name }
    end

    sample.merge!(i_enums)
  end

  def add_entity(sample, key = nil, e_entity)
    i_entity = {
      'id' => e_entity.id,
      'name' => e_entity.name
    }

    key ||= e_entity.class.to_s.tableize.singularize
    sample[key] = i_entity
    sample
  end

  def add_entities(sample, key, e_entities)
    i_entities = e_entities.map do |e_entity|
      {
        'id' => e_entity.id,
        'name' => e_entity.name
      }
    end

    sample[key] = i_entities
    sample
  end

  def add_user_attributes(sample, e_user_hash)
    e_user_hash.each do |name_field, user|
      sample[name_field] = { 'id' => user.id,
                             'name' => user.name }
    end
  end

  def add_default_user(sample, name_field)
    sample[name_field] = { 'id' => 1000,
                           'name' => 'Nemo Name' }
  end
end
