require 'net/http'
require 'uri'
require 'json'

module ModificationB2bSync
  class Client
    LIMIT = 50

    def url
      @url ||= setting('url')
    end

    def api_key
      @api_key ||= setting('api_key')
    end

    def get(type, id)
      get_response(type, id: id)
    end

    def get_all(type, available_assoc: nil, filter: nil, offset: 0)
      get_response(type, id: nil, available_assoc: available_assoc, filter: filter, offset: offset)
    end

    private

    def get_response(type, id: nil, available_assoc: nil, filter: nil, offset: 0, limit: LIMIT)
      uri = build_uri(type, id: id, additional: { limit: limit, available_assoc: available_assoc, filter: filter, offset: offset })
      request = build_request(uri)
      req_options = build_req_options(uri)

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      data = json_to_hash(response)
      response_log(response, type, offset, data, limit, uri)

      data
    end

    def response_log(response, type, _offset, data, limit, _uri)
      if limit == 1
        message = "Received the total count of objects: #{data['total_count']}. CODE='#{response.code}', MESSAGE='#{response.message}'"
      else
        if data[type.pluralize]&.count == 1
          number = "1 piece"
        elsif data[type]
          number = "1 #{type}"
        else
          number = "#{data[type.pluralize]&.count} pieces"
        end
        message = "Response received of #{number}. CODE='#{response.code}', MESSAGE='#{response.message}'"
      end
      ::EasyRakeTaskB2bSynchronizing.log_b2b_info(message)
    end

    def build_request(uri)
      request = Net::HTTP::Get.new(uri)
      request.content_type = 'application/json'
      request['X-Redmine-Api-Key'] = api_key
      request
    end

    def build_uri(type, id: nil, additional: {})
      return nil unless type

      uri = URI.parse(url)
      uri.path = "/#{type.pluralize}" << (id ? "/#{id}" : '') << '.json'
      query = additional.each_with_object({}) { |(key, value), obj| obj.merge!(query_attr(key, value, type)) }

      uri.query = URI.encode_www_form(query)
      uri
    end

    def query_attr(attr, value, type)
      return {} unless value

      case attr
      when :available_assoc
        { include: value }
      when :limit, :offset
        { attr => value }
      when :filter
        { set_filter: 1, **select_filter(value, type) }
      end
    end

    def select_filter(filter, type)
      filters = {}
      if filter.key?(:updated_on)
        interval = filter[:updated_on][:interval]
        period = case filter[:updated_on][:period]
                 when 'monthly'
                   interval.month
                 when 'daily'
                   interval.day
                 when 'hourly'
                   interval.hour
                 when 'minutes'
                   interval.minute
                 end
        datetime_now = DateTime.now
        lower_datetime = datetime_now - period
        filters.merge!({ "f[#{set_updated_on_field(type)}]" => "#{lower_datetime}|#{datetime_now}" })
      end

      filters.merge!({ 'f[entity_type]' => filter[:entity_type].join('|') }) if filter.key?(:entity_type)

      filters
    end

    def set_updated_on_field(type)
      ::EasyRakeTaskB2bSynchronizing::B2B_UPDATED_ON_FILTERS[type]
    end

    def build_req_options(uri)
      { use_ssl: uri.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE }
    end

    def json_to_hash(json)
      JSON.parse(json.body)
    end

    def setting(attr)
      ::EasySetting.value("modification_b2b_sync_#{attr}")
    end

  end
end
