module ModificationB2bSync
  module B2bExternalIdSafeAttribute

    def self.included(base)
      base.class_eval do
        safe_attributes('b2b_external_id')
      end
    end

  end
end

RedmineExtensions::PatchManager.register_model_patch ::EasyRakeTaskB2bSynchronizing.b2b_field_safe_attribute, 'ModificationB2bSync::B2bExternalIdSafeAttribute'
