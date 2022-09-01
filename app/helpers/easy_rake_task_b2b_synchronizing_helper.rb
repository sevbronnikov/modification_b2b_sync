module EasyRakeTaskB2bSynchronizingHelper

  def get_synchronizing_data
    ModificationB2bSync::Synchronizable.all
  end

  def synchronizing_data_field(view, task, synchronizing_data)
    tag_data =
      if synchronizing_data.parent.present?
        { parent_synchronizable: synchronizing_data.parent }
      else
        { disables: "input[data-parent-synchronizable=#{synchronizing_data.name}]" }
      end
    tag = view.check_box_tag('easy_rake_task[settings][b2b_types][]',
                             synchronizing_data.name,
                             task.b2b_types&.include?(synchronizing_data.name),
                             id: nil,
                             data: tag_data)
    text = l_or_humanize(synchronizing_data.name, prefix: 'label_')
    options = {}
    if synchronizing_data.parent.present?
      options[:class] = "parent"
    end
    view.content_tag(:label, tag + text, options)
  end

  def synchronization_grid(synchronizing_data)
    groups = synchronizing_data.group_by(&:parent)
    groups.clone.each do |k, _v|
      parent         = groups[nil].detect { |e| e.name == k }
      groups[parent] = groups.delete(k)
      groups[nil].delete(parent)
    end

    groups
  end

end
