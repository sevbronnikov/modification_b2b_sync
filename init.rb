Redmine::Plugin.register :modification_b2b_sync do
  name 'modification_b2b_sync'
  author 'modification_b2b_sync_author'
  author_url 'modification_b2b_sync_author_url'
  description 'modification_b2b_sync_description'
  version '2022'

  # requires_redmine_plugin :easy_extensions, version_or_higher: '2019'

  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
  # should_be_disabled false
  # categories [:other]
  # visible(true)

  settings partial: 'modification_b2b_sync', only_easy: true, easy_settings: { url: '',
                                                                               api_key: '',
                                                                               default_user_id: '',
                                                                               default_project_id: '',
                                                                               default_campaign_id: '' }
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end
