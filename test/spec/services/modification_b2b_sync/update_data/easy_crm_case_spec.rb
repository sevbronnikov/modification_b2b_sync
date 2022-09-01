require 'easy_extensions/spec_helper'

describe ::ModificationB2bSync::UpdateData::EasyCrmCase, logged: :admin do
  include_context 'b2b service base'
  include_context 'b2b service easy_crm_case'

  describe '#call' do
    let(:default_user) { FactoryBot.create(:user) }
    let(:default_project) { FactoryBot.create(:project) }
    let(:external_project) { FactoryBot.create(:project) }
    let(:internal_project) { FactoryBot.create(:project, b2b_external_id: external_project.id) }
    let(:external_crm_case_status) { FactoryBot.create(:easy_crm_case_status, is_easy_contact_required: false) }
    let(:internal_crm_case_status) { FactoryBot.create(:easy_crm_case_status, b2b_external_id: external_crm_case_status.id, is_easy_contact_required: false) }

    before do
      internal_project
      internal_crm_case_status
    end

    around(:each) do |example|
      with_easy_settings({ modification_b2b_sync_default_user_id: default_user.id,
                           modification_b2b_sync_default_project_id: default_project.id }) { example.run }
    end

    context 'with simple attributes' do
      let(:params) { crm_case_sample(crm_case_status: external_crm_case_status,
                                     project: external_project) }

      it 'creates and connects existing internal project' do
        described_class.call(params)
        new_crm_case = EasyCrmCase.find_by(b2b_external_id: params['id'].to_s)
        expect(new_crm_case).not_to be_nil

        expect(new_crm_case.project.b2b_external_id).to eq(params['project']['id'].to_s)

        simple_attributes.each do |name|
          next unless params[name]

          case name
          when 'contract_date', 'paid_on', 'next_action', 'closed_on', 'locked_at', 'unlocked_at',
            'price', 'price_EUR', 'price_USD', 'adjusted_value'
            expect(new_crm_case.send(name).to_s).to eq(params[name])
          else
            expect(new_crm_case.send(name)).to eq(params[name])
          end
        end
      end
    end

    context 'with user attributes' do
      let(:external_users_hash) { create_external_users }
      let(:internal_users_hash) { create_internal_users(external_users_hash) }
      let(:params) { crm_case_sample(crm_case_status: external_crm_case_status,
                                     project: external_project,
                                     with_users: external_users_hash) }

      it 'creates and connects users' do
        internal_users_hash

        described_class.call(params)
        new_crm_case = EasyCrmCase.find_by(b2b_external_id: params['id'].to_s)
        expect(new_crm_case).not_to be_nil

        user_attributes.each do |name|
          if params[name]
            if name == 'easy_last_updated_by'
              expect(new_crm_case.send(name)).to eq(User.current)
            else
              expect(new_crm_case.send(name).b2b_external_id).to eq(params[name]['id'].to_s)
            end
          else
            expect(new_crm_case.send(name)).to eq(nil)
          end
        end
      end
    end

    context 'without some user' do
      let(:params) { crm_case_sample(crm_case_status: external_crm_case_status,
                                     project: external_project,
                                     with_default_user: user_attributes.first) }

      it 'creates and connects default user' do
        described_class.call(params)
        new_crm_case = EasyCrmCase.find_by(b2b_external_id: params['id'].to_s)
        expect(new_crm_case).not_to be_nil

        user_attributes.each do |name|
          if params[name]
            expect(new_crm_case.send(name)).to eq(default_user)
          else
            if name == 'easy_last_updated_by'
              expect(new_crm_case.send(name)).to eq(User.current)
            else
              expect(new_crm_case.send(name)).to eq(nil)
            end
          end
        end
      end
    end

    context 'with missing internal project' do
      let(:internal_project) { FactoryBot.create(:project, b2b_external_id: nil) }
      let(:params) { crm_case_sample(crm_case_status: external_crm_case_status,
                                     project: external_project) }

      it 'creates and connects default project' do
        described_class.call(params)
        new_crm_case = EasyCrmCase.find_by(b2b_external_id: params['id'].to_s)
        expect(new_crm_case).not_to be_nil

        expect(new_crm_case.project).to eq(default_project)
      end
    end

    context 'with account' do
      let(:external_contact_type) { FactoryBot.create(:easy_contact_type, type_name: 'Account', internal_name: 'account') }
      let(:internal_contact_type) { FactoryBot.create(:easy_contact_type, type_name: 'Account', internal_name: 'account', b2b_external_id: external_contact_type.id) }
      let(:external_account) { FactoryBot.create(:easy_contact, easy_contact_type: external_contact_type) }
      let(:internal_account) { FactoryBot.create(:easy_contact, easy_contact_type: internal_contact_type, b2b_external_id: external_account.id) }
      let(:internal_project) { FactoryBot.create(:project, b2b_external_id: nil) }
      let(:params) { crm_case_sample(crm_case_status: external_crm_case_status,
                                     project: external_project,
                                     with_account: external_account) }

      # easy_crm_case will not be valid when the account will be absent if is_easy_contact_required = true
      it 'creates and connects account' do
        internal_account

        described_class.call(params)
        new_crm_case = EasyCrmCase.find_by(b2b_external_id: params['id'].to_s)
        expect(new_crm_case).not_to be_nil

        expect(new_crm_case.account.b2b_external_id).to eq(params['account']['id'].to_s)
      end
    end

    context 'without account' do
      let(:internal_project) { FactoryBot.create(:project, b2b_external_id: nil) }
      let(:params) { crm_case_sample(crm_case_status: external_crm_case_status,
                                     project: external_project) }

      # easy_crm_case will not be valid when the account will be absent if is_easy_contact_required = true
      it 'creates with nil account' do
        described_class.call(params)
        new_crm_case = EasyCrmCase.find_by(b2b_external_id: params['id'].to_s)
        expect(new_crm_case).not_to be_nil

        expect(new_crm_case.account).to be_nil
      end
    end

    context 'without account and with is_easy_contact_required = true' do
      let(:external_crm_case_status) { FactoryBot.create(:easy_crm_case_status, is_easy_contact_required: true) }
      let(:internal_crm_case_status) { FactoryBot.create(:easy_crm_case_status, b2b_external_id: external_crm_case_status.id, is_easy_contact_required: true) }
      let(:internal_project) { FactoryBot.create(:project, b2b_external_id: nil) }
      let(:params) { crm_case_sample(crm_case_status: external_crm_case_status,
                                     project: external_project) }

      # easy_crm_case will not be valid when the account will be absent if is_easy_contact_required = true

      it 'not creates' do
        described_class.call(params)
        new_crm_case = EasyCrmCase.find_by(b2b_external_id: params['id'].to_s)
        expect(new_crm_case).to be_nil
      end
    end

    context '(with enumerations)' do
      let(:external_enums) { create_external_enumerations }
      let(:internal_enums) { create_internal_enumerations(external_enums) }
      let(:params) { crm_case_sample(crm_case_status: external_crm_case_status,
                                     project: external_project,
                                     with_enums: external_enums) }

      it 'creates and connects enumerations' do
        internal_enums

        described_class.call(params)
        new_crm_case = EasyCrmCase.find_by(b2b_external_id: params['id'].to_s)
        expect(new_crm_case).not_to be_nil

        enum_attributes.each do |name|
          if params[name]
            expect(new_crm_case.send(name).b2b_external_id).to eq(params[name]['id'].to_s)
          else
            expect(new_crm_case.send(name)).to be_nil
          end
        end
      end
    end

    context '(without enumerations)' do
      let(:params) { crm_case_sample(crm_case_status: external_crm_case_status,
                                     project: external_project) }

      it 'creates with nil enumerations' do
        described_class.call(params)
        new_crm_case = EasyCrmCase.find_by(b2b_external_id: params['id'].to_s)
        expect(new_crm_case).not_to be_nil

        enum_attributes.each do |name|
          expect(new_crm_case.send(name)).to be_nil
        end
      end
    end

    context "(with custom fields)" do
      let(:external_cfs) { create_external_custom_fields }
      let(:internal_cfs) { create_internal_custom_fields(external_cfs) }
      let(:external_crm_case_status) { FactoryBot.create(:easy_crm_case_status, custom_fields: external_cfs) }
      let(:internal_crm_case_status) { FactoryBot.create(:easy_crm_case_status, b2b_external_id: external_crm_case_status.id, custom_fields: internal_cfs) }

      let(:params) { crm_case_sample(crm_case_status: external_crm_case_status,
                                     project: external_project,
                                     with_cfs: external_cfs)
      }

      it 'creates and connects custom fields' do
        internal_cfs

        described_class.call(params)
        new_crm_case = EasyCrmCase.find_by(b2b_external_id: params['id'].to_s)
        expect(new_crm_case).not_to be_nil

        new_crm_case.custom_field_values.each do |cfv|
          expect(cfv.value).to eq(params['custom_fields'].find { |ocf| ocf['id'].to_s == cfv.custom_field.b2b_external_id }['value'])
        end
      end
    end
  end
end
