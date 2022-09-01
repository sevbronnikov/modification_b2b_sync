require 'easy_extensions/spec_helper'

describe ::ModificationB2bSync::UpdateData::EasyPersonalContact, logged: :admin do
  include_context 'b2b service base'
  include_context 'b2b service easy_personal_contact'

  describe '#call' do
    let(:default_user) { FactoryBot.create(:user) }
    let(:external_contact_type) { FactoryBot.create(:easy_contact_type, type_name: 'Account', internal_name: 'account') }
    let(:internal_contact_type) { FactoryBot.create(:easy_contact_type, type_name: 'Account', internal_name: 'account', b2b_external_id: external_contact_type.id) }
    let(:external_account) { FactoryBot.create(:easy_contact, easy_contact_type: external_contact_type) }
    let(:internal_account) { FactoryBot.create(:easy_contact, easy_contact_type: internal_contact_type, b2b_external_id: external_account.id) }
    let(:external_personal_contact_type) { FactoryBot.create(:easy_personal_contact_type) }
    let(:internal_personal_contact_type) { FactoryBot.create(:easy_personal_contact_type, b2b_external_id: external_personal_contact_type.id) }

    around(:each) do |example|
      with_easy_settings(modification_b2b_sync_default_user_id: default_user.id) { example.run }
    end

    before do
      internal_contact_type
      internal_account
      internal_personal_contact_type
    end

    context '(with simple attributes)' do
      let(:params) { personal_contact_sample(personal_contact_type: external_personal_contact_type,
                                             with_easy_contact: external_account,
                                             with_location_codes: true) }

      it 'creates with account' do
        described_class.call(params)
        new_contact = EasyPersonalContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil

        simple_attributes.each do |name|
          next unless params[name]

          expect(new_contact.send(name)).to eq(params[name])
        end

        expect(new_contact.easy_personal_contact_type.b2b_external_id).to eq(params['easy_personal_contact_type']['id'].to_s)

        location_codes_attributes.each do |name|
          if params[name]
            expect(new_contact.send("#{name}_code")).to eq(params[name]['code'])
          else
            expect(new_contact.send("#{name}_code")).to be_nil
          end
        end

        # account or easy_partner
        expect(new_contact.account.b2b_external_id).to eq(params['easy_contact']['id'].to_s)
      end
    end

    context 'without account' do
      let(:params) { personal_contact_sample(personal_contact_type: external_personal_contact_type) }

      it 'not creates' do
        described_class.call(params)
        new_contact = EasyPersonalContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).to be_nil
      end
    end

    context 'with blank location_codes_attributes' do
      let(:params) { personal_contact_sample(personal_contact_type: external_personal_contact_type,
                                             with_easy_contact: external_account) }

      it 'creates with nil location_codes' do
        described_class.call(params)
        new_contact = EasyPersonalContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil


        location_codes_attributes.each do |name|
          expect(new_contact.send("#{name}_code")).to be_nil
        end
      end
    end

    context '(with user attributes)' do
      let(:external_users_hash) { create_external_users }
      let(:internal_users_hash) { create_internal_users(external_users_hash) }
      let(:params) { personal_contact_sample(personal_contact_type: external_personal_contact_type,
                                             with_easy_contact: external_account,
                                             with_users: external_users_hash) }

      it 'creates and connects users' do
        internal_users_hash

        described_class.call(params)
        new_contact = EasyPersonalContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil

        user_attributes.each do |name|
          if params[name]
            expect(new_contact.send(name).b2b_external_id).to eq(params[name]['id'].to_s)
          else
            expect(new_contact.send(name)).to eq(nil)
          end
        end
      end
    end

    context '(without some user)' do
      let(:params) { personal_contact_sample(personal_contact_type: external_personal_contact_type,
                                             with_easy_contact: external_account,
                                             with_default_user: user_attributes.first) }

      it 'creates and connects default user' do
        described_class.call(params)
        new_contact = EasyPersonalContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil

        user_attributes.each do |name|
          if params[name]
            expect(new_contact.send(name)).to eq(default_user)
          else
            expect(new_contact.send(name)).to eq(nil)
          end
        end
      end
    end

    # context "(with partner)" do
    # ------------------------------------------------
    # Adding easy_partner is not included in the task.
    # b2b_external_id not added to easy_partner.
    # ------------------------------------------------
    # end

    context "(with custom fields)" do
      let(:external_cfs) { create_external_custom_fields }
      let(:internal_cfs) { create_internal_custom_fields(external_cfs) }
      # legacy code
      # let(:external_personal_contact_type) { FactoryBot.create(:easy_personal_contact_type) }
      # let(:internal_personal_contact_type) { FactoryBot.create(:easy_personal_contact_type,
      #                                                          b2b_external_id: external_personal_contact_type.id) }
      let(:params) { personal_contact_sample(personal_contact_type: external_personal_contact_type,
                                             with_easy_contact: external_account,
                                             with_cfs: external_cfs) }

      it 'creates and connects custom fields' do
        internal_cfs

        described_class.call(params)
        new_contact = EasyPersonalContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil

        # Do personal contacts have a separate logic?
        new_contact.custom_field_values.select { |cfv| internal_cfs.include?(cfv.custom_field) }.each do |cfv|
          expect(cfv.value).to eq(params['custom_fields'].find { |ocf| ocf['id'].to_s == cfv.custom_field.b2b_external_id }['value'])
        end
      end
    end
  end
end
