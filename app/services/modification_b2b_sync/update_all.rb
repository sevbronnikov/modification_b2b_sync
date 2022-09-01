module ModificationB2bSync
  class UpdateAll < ::ModificationB2bSync::Base

    def call
      data_types.each do |data_type|
        start_log(data_type)
        @errors_number = 0
        @successful_updates_number = 0

        @offset = 0

        all_filters = attributes[:filter].merge(sales_activities_filter(data_type))
        total_count = client.get_all(data_type, filter:  all_filters)['total_count']

        while @offset < total_count
          response = client.get_all(data_type, offset: @offset, filter:  all_filters)
          set_and_run_update_type(data_type, response)

          @offset += limit
          sleep 60 if (data_type == 'easy_contact') || (@offset % limit**2).zero?
        end

        end_log(data_type)
      end
    end

    private

    def sales_activities_filter(data_type)
      if data_type == 'easy_entity_activity'
        { entity_type: ['EasyCrmCase', 'EasyLead'] }
      else
        {}
      end
    end

    def counting_update_responses(update_response)
      if update_response[:success?]
        @successful_updates_number += 1
      else
        @errors_number += 1
      end
    end

    def set_and_run_update_type(data_type, response)
      case data_type
      when 'easy_contact'
        response[data_type.pluralize].each do |entity|
          update_response = entity_type(data_type).call(client.get(data_type, entity['id'])[data_type])
          counting_update_responses(update_response)
        end
      when 'easy_personal_contact', 'easy_crm_case', 'easy_lead', 'easy_entity_activity'
        update_entities(response[data_type.pluralize], data_type)
      else
        log_info('ERROR -> Unknown entity')
      end
    end

    def update_entities(all_data, data_type)
      return if all_data.blank?

      all_data.each do |data|
        update_response = entity_type(data_type).call(data)
        counting_update_responses(update_response)
      end
    end

    def data_types
      @data_types ||= attributes[:data_types]
    end

    def entity_type(data_type = nil)
      @entity_types ||= {}
      @entity_types[data_type] ||= "::ModificationB2bSync::UpdateData::#{data_type.classify}".constantize if data_type
    end

    def start_log(data_type)
      message = "START -> #{data_type.pluralize.humanize(capitalize: false)} update"
      log_info(message)
    end

    def end_log(data_type)
      message = "END -> #{data_type.pluralize.humanize(capitalize: false)} updated. Number of updates = #{@successful_updates_number}, number of errors = #{@errors_number}\n"
      log_info(message)
    end

  end
end
