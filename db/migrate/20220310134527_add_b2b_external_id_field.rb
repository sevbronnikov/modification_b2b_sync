class AddB2bExternalIdField < ActiveRecord::Migration[6.1]
  OTHER_TABLES = %i[enumerations easy_crm_case_statuses
                    custom_fields projects easy_campaigns
                    easy_contact_type easy_personal_contact_types
                    easy_entity_activities users].freeze

  def up
    EasyRakeTaskB2bSynchronizing::B2B_TYPES.each do |entity|
      add_column :"#{entity.pluralize}", :b2b_external_id, :string, if_not_exists: true
    end

    OTHER_TABLES.each do |table|
      add_column table, :b2b_external_id, :string, if_not_exists: true
    end
  end

  def down
    EasyRakeTaskB2bSynchronizing::B2B_TYPES.each do |entity|
      remove_column :"#{entity.pluralize}", :b2b_external_id, :string, if_exists: true
    end

    OTHER_TABLES.each do |table|
      remove_column table, :b2b_external_id, :string, if_exists: true
    end
  end

end
