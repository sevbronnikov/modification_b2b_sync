class B2bSynchronizingLogsController < ApplicationController
  before_action :require_admin

  def downloads_b2b_log
    return render_404 unless File.exist?(Rails.root.join('log/b2b_sync.log'))

    send_file Rails.root.join('log/b2b_sync.log'), disposition: :attachment
  end

end
