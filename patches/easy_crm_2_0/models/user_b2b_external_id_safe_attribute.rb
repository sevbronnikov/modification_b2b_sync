module ModificationB2bSync
  module UserB2bExternalIdSafeAttribute

    def self.included(base)
      base.class_eval do
        safe_attributes('b2b_external_id', if: ->(_user, current_user) { current_user.admin? })
      end
    end

  end
end

RedmineExtensions::PatchManager.register_model_patch 'User', 'ModificationB2bSync::UserB2bExternalIdSafeAttribute'
