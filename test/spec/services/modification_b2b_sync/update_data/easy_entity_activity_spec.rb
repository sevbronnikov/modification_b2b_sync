require 'easy_extensions/spec_helper'

describe ::ModificationB2bSync::UpdateData::EasyEntityActivity, logged: :admin do
  include_context 'b2b service base'
  include_context 'b2b service easy_entity_activity'

  describe '#call' do
    let(:default_user) { FactoryBot.create(:user) }
    let(:default_project) { FactoryBot.create(:project) }
    let(:external_entities) { create_external_related_entities }
    let(:internal_entities) { create_internal_related_entities(external_entities) }
    let(:external_enums) { create_external_enumerations }
    let(:internal_enums) { create_internal_enumerations(external_enums) }
    let(:params) { sales_activity_sample(with_entity: external_entities[:external_crm_case], with_category: external_enums.first) }

    around(:each) do |example|
      with_easy_settings({ modification_b2b_sync_default_user_id: default_user.id,
                           modification_b2b_sync_default_project_id: default_project.id }) { example.run }
    end

    before do
      internal_entities
      internal_enums
    end

    context 'with simple attributes' do
      it 'creates' do
        described_class.call(params)
        new_sales_activity = EasyEntityActivity.find_by(b2b_external_id: params['id'].to_s)
        expect(new_sales_activity).not_to be_nil

        simple_attributes.each do |name|
          next unless params[name]

          case name
          when 'start_time', 'end_time'
            # new_sales_activity.start_time.utc.iso8601
            expect(new_sales_activity.send(name).to_i).to eq(EasyUtils::DateUtils.build_datetime_from_params(params[name]).to_i)
          when ''
            expect(new_sales_activity.send(name).to_s).to eq(params[name])
          else
            expect(new_sales_activity.send(name)).to eq(params[name])
          end
        end
      end
    end

    context 'with user attributes' do
      let(:external_users_hash) { create_external_users }
      let(:internal_users_hash) { create_internal_users(external_users_hash) }
      let(:params) { sales_activity_sample(with_entity: external_entities[:external_crm_case],
                                           with_category: external_enums.first,
                                           with_users: external_users_hash) }

      it 'creates and connects users' do
        internal_users_hash

        described_class.call(params)
        new_sales_activity = EasyEntityActivity.find_by(b2b_external_id: params['id'].to_s)
        expect(new_sales_activity).not_to be_nil

        user_attributes.each do |name|
          if params[name]
            expect(new_sales_activity.send(name).b2b_external_id).to eq(params[name]['id'].to_s)
          else
            expect(new_sales_activity.send(name)).to eq(nil)
          end
        end
      end
    end

    context 'without some user' do
      let(:params) { sales_activity_sample(with_entity: external_entities[:external_crm_case],
                                           with_category: external_enums.first,
                                           with_default_user: user_attributes.first) }

      it 'creates and connects default user' do
        described_class.call(params)
        new_sales_activity = EasyEntityActivity.find_by(b2b_external_id: params['id'].to_s)
        expect(new_sales_activity).not_to be_nil

        user_attributes.each do |name|
          if params[name]
            expect(new_sales_activity.send(name)).to eq(default_user)
          else
            expect(new_sales_activity.send(name)).to eq(nil)
          end
        end
      end
    end

    context 'with entity and category attribute' do
      let(:params) { sales_activity_sample(with_entity: external_entities[:external_crm_case],
                                           with_category: external_enums.first) }

      it 'creates and connects easy_crm_case and category' do
        described_class.call(params)
        new_sales_activity = EasyEntityActivity.find_by(b2b_external_id: params['id'].to_s)
        expect(new_sales_activity).not_to be_nil

        expect(new_sales_activity.category.b2b_external_id).to eq(params['category']['id'].to_s)
        expect(new_sales_activity.entity.b2b_external_id).to eq(params['entity']['id'].to_s)
      end
    end

    context 'with entity' do
      let(:params) { sales_activity_sample(with_entity: external_entities[:external_lead],
                                           with_category: external_enums.first) }

      it 'creates and connects easy_lead' do
        described_class.call(params)
        new_sales_activity = EasyEntityActivity.find_by(b2b_external_id: params['id'].to_s)
        expect(new_sales_activity).not_to be_nil

        expect(new_sales_activity.entity.b2b_external_id).to eq(params['entity']['id'].to_s)
      end
    end

    context 'without category attribute' do
      let(:params) { sales_activity_sample(with_entity: external_entities[:external_crm_case]) }

      it 'creates and connects easy_crm_case and category' do
        described_class.call(params)
        new_sales_activity = EasyEntityActivity.find_by(b2b_external_id: params['id'].to_s)
        expect(new_sales_activity).to be_nil
      end
    end

    context 'with contact_attendees attribute' do
      let(:external_contact_attendees) { FactoryBot.create_pair(:easy_contact, easy_contact_type: external_entities[:external_account_contact_type]) }
      let(:internal_contact_attendees) { external_contact_attendees.map{ |ca| FactoryBot.create(:easy_contact, easy_contact_type: external_entities[:external_account_contact_type],b2b_external_id: ca.id) } }
      let(:params) { sales_activity_sample(with_entity: external_entities[:external_crm_case],
                                           with_category: external_enums.first,
                                           with_contact_attendees: external_contact_attendees) }

      it 'creates and connects easy_contacts' do
        internal_contact_attendees

        described_class.call(params)
        new_sales_activity = EasyEntityActivity.find_by(b2b_external_id: params['id'].to_s)
        expect(new_sales_activity).not_to be_nil

        actual = new_sales_activity.easy_entity_activity_contacts.map(&:b2b_external_id)
        expected = params['contact_attendees'].map { |ca| ca['id'].to_s }

        expect(actual).to eq(expected)
      end
    end

    context 'with users_attendees attribute' do
      let(:external_users_attendees) { FactoryBot.create_pair(:user) }
      let(:internal_users_attendees) { external_users_attendees.map{ |ua| FactoryBot.create(:user, b2b_external_id: ua.id) } }
      let(:params) { sales_activity_sample(with_entity: external_entities[:external_crm_case],
                                           with_category: external_enums.first,
                                           with_users_attendees: external_users_attendees) }

      it 'creates and connects users' do
        internal_users_attendees

        described_class.call(params)
        new_sales_activity = EasyEntityActivity.find_by(b2b_external_id: params['id'].to_s)
        expect(new_sales_activity).not_to be_nil

        expect(new_sales_activity.easy_entity_activity_users.map(&:b2b_external_id)).to eq(params['users_attendees'].map{ |ua| ua['id'].to_s})
      end
    end

    context 'with users_attendees attribute blank' do
      let(:params) { sales_activity_sample(with_entity: external_entities[:external_crm_case],
                                           with_category: external_enums.first) }

      it 'creates and connects users' do
        described_class.call(params)
        new_sales_activity = EasyEntityActivity.find_by(b2b_external_id: params['id'].to_s)
        expect(new_sales_activity).not_to be_nil

        expect(new_sales_activity.easy_entity_activity_users).to be_blank
      end
    end

    context 'with users_attendees attribute without some user' do
      let(:external_users_attendees) { [OpenStruct.new(id: 1000, name: 'Some User')] }
      let(:params) { sales_activity_sample(with_entity: external_entities[:external_crm_case],
                                           with_category: external_enums.first,
                                           with_users_attendees: external_users_attendees) }

      it 'creates and default user' do
        described_class.call(params)
        new_sales_activity = EasyEntityActivity.find_by(b2b_external_id: params['id'].to_s)
        expect(new_sales_activity).not_to be_nil

        expect(new_sales_activity.easy_entity_activity_users).to include(default_user)
      end
    end
  end
end
