class EasyRakeTaskB2bSynchronizing < EasyRakeTask
  B2B_TYPES = %w[easy_contact easy_personal_contact easy_crm_case easy_lead easy_entity_activity].freeze
  B2B_UPDATED_ON_FILTERS = { 'easy_contact' => 'updated_on',
                             'easy_personal_contact' => 'updated_at',
                             'easy_crm_case' => 'updated_at',
                             'easy_lead' => 'updated_at',
                             'easy_entity_activity' => 'updated_at' }.freeze
  B2B_CLASSIFY_TYPES = B2B_TYPES.map(&:classify).freeze
  B2B_FIELD_STATUSES_AND_TYPES = %w[EasyCrmCaseStatus EasyContactType EasyPersonalContactType].freeze
  B2B_FIELD_BASE_EP_TYPES = %w[Project].freeze # User is declared separately
  B2B_FIELD_CF_TYPES = %w[EasyContactCustomField EasyPersonalContactCustomField EasyCrmCaseCustomField EasyLeadCustomField].freeze

  store_accessor :settings, :b2b_types

  def execute
    ::ModificationB2bSync::UpdateAll.call(data_types: b2b_types, filter: { updated_on: { period: period, interval: interval } })
  end

  def self.b2b_field_enumeration_types
    enumeration_types = []
    B2B_TYPES.each do |type|
      names = updater_class(type).const_get(:ENUM_ATTRIBUTES)
      enumeration_types.concat(names)
    end

    enumeration_types.map(&:classify)
  end

  def b2b_types
    return [] unless settings['b2b_types'].is_a?(Array)

    settings['b2b_types'].include?('all') ? B2B_TYPES : settings['b2b_types']
  end

  def settings_view_path
    'easy_rake_tasks/settings/easy_rake_task_b2b_synchronizing'
  end

  def registered_in_plugin
    :modification_b2b_sync
  end

  def self.b2b_field_safe_attribute
    #   Enumeration don't use save_attributes method
    B2B_FIELD_BASE_EP_TYPES + B2B_FIELD_STATUSES_AND_TYPES + B2B_FIELD_CF_TYPES
  end

  def self.b2b_field_unique_attribute
    ['User'] + B2B_FIELD_BASE_EP_TYPES + B2B_CLASSIFY_TYPES + B2B_FIELD_STATUSES_AND_TYPES + b2b_field_enumeration_types + B2B_FIELD_CF_TYPES
  end

  def self.my_logger
    @@b2b_sync_logger ||= Logger.new(Rails.root.join('log/b2b_sync.log'))
  end

  def self.log_b2b_info(message)
    log_info(message, my_logger)
  end

  def additional_task_info_view_path
    'easy_rake_tasks/downloads_logs_button'
  end

  class << self

    private

    def updater_class(type)
      "::ModificationB2bSync::UpdateData::#{type.classify}".constantize
    end

  end

end
