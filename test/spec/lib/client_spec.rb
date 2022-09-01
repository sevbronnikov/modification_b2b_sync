require 'easy_extensions/spec_helper'

describe ::ModificationB2bSync::Client, logged: :admin do
  let(:filter) { { updated_on: { period: 'monthly', interval: 1 } } }
  let(:limit) { described_class::LIMIT  }

  around(:each) do |example|
    with_easy_settings(modification_b2b_sync_url: 'https://example.com',
                       modification_b2b_sync_api_key: 'api_key123456789') { example.run }
  end

  describe '#get_all' do

    context 'calls correct filter for' do
      let(:data_type) { 'easy_contact' }

      it 'easy_contact' do
        uri = subject.send('build_uri', data_type, id: nil, additional: { limit: limit, available_assoc: nil, filter: filter, offset: 0 })
        expect(uri.query).to include('updated_on')
      end
    end

    context 'calls correct filter for' do
      let(:data_type) { 'easy_personal_contact' }

      it 'easy_personal_contact' do
        uri = subject.send('build_uri', data_type, id: nil, additional: { limit: limit, available_assoc: nil, filter: filter, offset: 0 })
        expect(uri.query).to include('updated_at')
      end
    end

    context 'calls correct filter for' do
      let(:data_type) { 'easy_crm_case' }

      it 'easy_crm_case' do
        uri = subject.send('build_uri', data_type, id: nil, additional: { limit: limit, available_assoc: nil, filter: filter, offset: 0 })
        expect(uri.query).to include('updated_at')
      end
    end

    context 'calls correct filter for' do
      let(:data_type) { 'easy_lead' }

      it 'easy_lead' do
        uri = subject.send('build_uri', data_type, id: nil, additional: { limit: limit, available_assoc: nil, filter: filter, offset: 0 })
        expect(uri.query).to include('updated_at')
      end
    end

    context 'calls correct filter for' do
      let(:data_type) { 'easy_entity_activity' }

      it 'easy_entity_activity' do
        all_filters = filter.merge({ entity_type: ['EasyCrmCase', 'EasyLead'] })
        uri = subject.send('build_uri', data_type, id: nil, additional: { limit: limit, available_assoc: nil, filter: all_filters, offset: 0 })
        expect(uri.query).to include('updated_at')
      end
    end

  end
end
