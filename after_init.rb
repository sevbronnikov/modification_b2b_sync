ActiveSupport.on_load(:easyproject, yield: true) do
  require 'modification_b2b_sync/internals'
  require 'modification_b2b_sync/hooks'
  require 'modification_b2b_sync/client'
  require 'modification_b2b_sync/synchronizable'
end

RedmineExtensions::Reloader.to_prepare do
  require_dependency 'easy_rake_task_b2b_synchronizing'
end
