class CreateEasyRakeTaskB2bSynchronizing < ActiveRecord::Migration[6.1]

  def up
    t         = EasyRakeTaskB2bSynchronizing.new(active: true, settings: {}, period: :daily, interval: 1, next_run_at: Time.now.beginning_of_day)
    t.builtin = 1
    t.save!
  end

  def down
    EasyRakeTaskB2bSynchronizing.destroy_all
  end

end
