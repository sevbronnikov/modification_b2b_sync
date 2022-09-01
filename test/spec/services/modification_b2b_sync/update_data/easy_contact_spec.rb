require 'easy_extensions/spec_helper'

describe ::ModificationB2bSync::UpdateData::EasyContact, logged: :admin do
  include_context 'b2b service base'
  include_context 'b2b service easy_contact'

  describe '#call' do
    let(:default_user) { FactoryBot.create(:user) }
    let(:external_contact_type) { FactoryBot.create(:easy_contact_type, type_name: 'Account', internal_name: 'account') }
    let(:internal_contact_type) { FactoryBot.create(:easy_contact_type, type_name: 'Account', internal_name: 'account', b2b_external_id: external_contact_type.id) }

    around(:each) do |example|
      with_easy_settings(modification_b2b_sync_default_user_id: default_user.id) { example.run }
    end
    before { internal_contact_type }

    context "(without parent, enumerations and custom fields when easy_contact don't exist)" do
      let(:params) { contact_sample(contact_type: external_contact_type, with_time_zone: :hash) }

      it 'creates with native attributes and time_zone hash' do
        described_class.call(params)
        new_contact = EasyContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil

        simple_attributes.each do |name|
          next unless params[name]

          case name
          when 'account_opened', 'account_closed', 'expected_revenues_this_year', 'last_year_revenues', 'lifetime_revenues'
            expect(new_contact.send(name).to_s).to eq(params[name])
          else
            expect(new_contact.send(name)).to eq(params[name])
          end
        end

        expect(new_contact.time_zone).to eq(params['time_zone']['name'])
        expect(new_contact.easy_contact_type.b2b_external_id).to eq(params['easy_contact_type']['id'].to_s)
      end
    end

    context "(without parent, enumerations and custom fields)" do
      let(:params) { contact_sample(contact_type: external_contact_type, with_time_zone: :string) }

      it 'creates with native attributes and time_zone string' do
        described_class.call(params)
        new_contact = EasyContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil

        expect(new_contact.time_zone).to eq(params['time_zone'])
      end
    end

    context "creates without time_zone" do
      let(:params) { contact_sample(contact_type: external_contact_type, with_time_zone: false) }

      it do
        described_class.call(params)
        new_contact = EasyContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil

        expect(new_contact.time_zone).to be_blank
      end
    end

    context "with user attributes" do
      let(:external_users_hash) { create_external_users }
      let(:internal_users_hash) { create_internal_users(external_users_hash) }
      let(:params) { contact_sample(contact_type: external_contact_type, with_users: external_users_hash) }

      it 'creates and connects users' do
        internal_users_hash

        described_class.call(params)
        new_contact = EasyContact.find_by(b2b_external_id: params['id'].to_s)
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

    context "without some user" do
      let(:params) { contact_sample(contact_type: external_contact_type, with_default_user: user_attributes.first) }

      it 'creates and connects default user' do
        described_class.call(params)
        new_contact = EasyContact.find_by(b2b_external_id: params['id'].to_s)
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

    context "(without parent, enumerations and custom fields when easy_contact don't exist)" do
      let(:params) { contact_sample(contact_type: external_contact_type, same_billing_attr: false) }

      it 'creates with different billing attributes' do
        described_class.call(params)
        new_contact = EasyContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil

        primary_billing_attributes.each do |name|
          next if name == 'vat_rate'

          expect(new_contact.primary_easy_billing_info.send(name)).to eq(params['billing_info'][name])
          expect(new_contact.contact_easy_billing_info.send(name)).to eq(params[name])
        end

        expect(new_contact.primary_easy_billing_info.vat_rate.to_s).to eq(params['billing_info']['vat_rate'])
        expect(new_contact.contact_easy_billing_info.vat_rate.to_s).to eq(params['vat_rate'])

        primary_billing_attributes.each do |name|
          expect(new_contact.primary_easy_billing_info.send(name)).not_to eq(new_contact.contact_easy_billing_info.send(name))
        end
      end
    end

    context "(without parent, enumerations and custom fields when easy_contact don't exist)" do
      let(:params) { contact_sample(contact_type: external_contact_type, same_billing_attr: true) }

      it 'creates with same billing attributes' do
        described_class.call(params)
        new_contact = EasyContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil

        primary_billing_attributes.each do |name|
          next if name == 'vat_rate'

          expect(new_contact.primary_easy_billing_info.send(name)).to eq(params['billing_info'][name])
          expect(new_contact.contact_easy_billing_info.send(name)).to eq(params[name])
        end

        expect(new_contact.primary_easy_billing_info.vat_rate.to_s).to eq(params['billing_info']['vat_rate'])
        expect(new_contact.contact_easy_billing_info.vat_rate.to_s).to eq(params['vat_rate'])

        primary_billing_attributes.each do |name|
          expect(new_contact.primary_easy_billing_info.send(name)).to eq(new_contact.contact_easy_billing_info.send(name))
        end
      end
    end

    context "(without enumerations and custom fields when easy_contact don't exist)" do
      let(:external_contact_parent) { FactoryBot.create(:easy_contact) }
      let(:internal_contact_parent) { FactoryBot.create(:easy_contact, b2b_external_id: external_contact_parent.id) }
      let(:params) { contact_sample(contact_type: external_contact_type, with_parent: external_contact_parent) }

      it 'creates and connects existing parent' do
        internal_contact_parent

        described_class.call(params)
        new_contact = EasyContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil
        expect(new_contact.parent.b2b_external_id).to eq(params['parent']['id'].to_s)
      end
    end

    context "with parent attribute blank" do
      let(:params) { contact_sample(contact_type: external_contact_type) }

      it 'creates with nil parent' do
        described_class.call(params)
        new_contact = EasyContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil
        expect(new_contact.parent).to be_nil
      end
    end

    context "(without enumerations and custom fields when easy_contact don't exist)" do
      let(:external_contact_parent) { FactoryBot.create(:easy_contact) }
      let(:params) { contact_sample(contact_type: external_contact_type, with_parent: external_contact_parent) }

      before do
        allow_any_instance_of(described_class).to receive(:get_parent).and_return(returned_parent(external_contact_parent.id))
      end

      it 'creates and connects returned parent' do
        described_class.call(params)
        new_contact = EasyContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil
        expect(new_contact.parent.b2b_external_id).to eq(external_contact_parent.id.to_s)
      end
    end

    context "(without parent and custom fields when easy_contact don't exist)" do
      let(:external_enums) { create_external_enumerations }
      let(:internal_enums) { create_internal_enumerations(external_enums) }
      let(:params) { contact_sample(contact_type: external_contact_type, with_enums: external_enums) }

      it 'creates and connects enumerations' do
        internal_enums

        described_class.call(params)
        new_contact = EasyContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil

        enum_attributes.each do |name|
          if params[name]
            expect(new_contact.send(name).b2b_external_id).to eq(params[name]['id'].to_s)
          else
            expect(new_contact.send(name)).to be_nil
          end
        end
      end
    end

    context 'without enumeration attributes' do
      let(:params) { contact_sample(contact_type: external_contact_type) }

      it 'creates with nil enumerations' do
        described_class.call(params)
        new_contact = EasyContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil

        enum_attributes.each do |name|
          expect(new_contact.send(name)).to be_nil
        end
      end
    end

    context "(without parent and enumerations when easy_contact don't exist)" do
      let(:external_cfs) { create_external_custom_fields }
      let(:internal_cfs) { create_internal_custom_fields(external_cfs) }
      let(:external_contact_type) { FactoryBot.create(:easy_contact_type,
                                                      type_name: 'Account',
                                                      internal_name: 'account',
                                                      custom_fields: external_cfs) }
      let(:internal_contact_type) { FactoryBot.create(:easy_contact_type,
                                                      type_name: 'Account',
                                                      internal_name: 'account',
                                                      custom_fields: internal_cfs,
                                                      b2b_external_id: external_contact_type.id) }

      let(:params) { contact_sample(contact_type: external_contact_type, with_cfs: external_cfs) }

      it 'creates and connects custom fields' do
        internal_cfs

        described_class.call(params)
        new_contact = EasyContact.find_by(b2b_external_id: params['id'].to_s)
        expect(new_contact).not_to be_nil

        new_contact.custom_field_values.each do |cfv|
          expect(cfv.value).to eq(params['custom_fields'].find { |ocf| ocf['id'].to_s == cfv.custom_field.b2b_external_id }['value'])
        end
      end
    end
  end
end
