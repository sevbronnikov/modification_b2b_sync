module ModificationB2bSync
  module EasyRakeTasksHelperPatch

    def self.included(base)
      base.class_eval do
        include EasyRakeTaskB2bSynchronizingHelper
      end
    end

  end
end

RedmineExtensions::PatchManager.register_helper_patch 'EasyRakeTasksHelper', 'ModificationB2bSync::EasyRakeTasksHelperPatch'
