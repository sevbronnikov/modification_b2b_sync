module ModificationB2bSync
  module B2bExternalIdUniqueAttribute

    def self.included(base)
      base.class_eval do
        validates :b2b_external_id, uniqueness: true, allow_blank: true, if: -> { respond_to?(:b2b_external_id) }
      end
    end

  end
end

RedmineExtensions::PatchManager.register_model_patch ::EasyRakeTaskB2bSynchronizing.b2b_field_unique_attribute, 'ModificationB2bSync::B2bExternalIdUniqueAttribute'
