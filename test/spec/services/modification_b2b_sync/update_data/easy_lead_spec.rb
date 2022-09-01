require 'easy_extensions/spec_helper'

describe ::ModificationB2bSync::UpdateData::EasyLead, logged: :admin do
  include_context 'b2b service base'
  include_context 'b2b service easy_lead'

  describe '#call' do
    let(:default_user) { FactoryBot.create(:user) }
    let(:default_project) { FactoryBot.create(:project) }
    let(:default_campaign) { FactoryBot.create(:easy_campaign) }

    around(:each) do |example|
      with_easy_settings({ modification_b2b_sync_default_user_id: default_user.id,
                           modification_b2b_sync_default_project_id: default_project.id,
                           modification_b2b_sync_default_campaign_id: default_campaign.id }) { example.run }
    end

    context 'with simple attributes' do
      let(:params) { lead_sample(is_processed: false) }

      it 'creates' do
        described_class.call(params)
        new_lead = EasyLead.find_by(b2b_external_id: params['id'].to_s)
        expect(new_lead).not_to be_nil

        simple_attributes.each do |name|
          next unless params[name]

          if params[name] == ''
            expect(new_lead.send(name).to_s).to eq(params[name])
          else
            expect(new_lead.send(name)).to eq(params[name])
          end
        end
      end
    end

    context 'with user attributes' do
      let(:external_users_hash) { create_external_users }
      let(:internal_users_hash) { create_internal_users(external_users_hash) }
      let(:params) { lead_sample(is_processed: false, with_users: external_users_hash) }

      it 'creates and connects users' do
        internal_users_hash

        described_class.call(params)
        new_lead = EasyLead.find_by(b2b_external_id: params['id'].to_s)
        expect(new_lead).not_to be_nil

        user_attributes.each do |name|
          if params[name]
            expect(new_lead.send(name).b2b_external_id).to eq(params[name]['id'].to_s)
          else
            expect(new_lead.send(name)).to be_nil
          end
        end
      end
    end

    context "without some user" do
      let(:params) { lead_sample(is_processed: false, with_default_user: user_attributes.first) }

      it 'creates and connects default user' do
        described_class.call(params)
        new_lead = EasyLead.find_by(b2b_external_id: params['id'].to_s)
        expect(new_lead).not_to be_nil

        user_attributes.each do |name|
          if params[name]
            expect(new_lead.send(name)).to eq(default_user)
          else
            expect(new_lead.send(name)).to be_nil
          end
        end
      end
    end

    context 'with is_processed = true and without campaign' do
      let(:params) { lead_sample(is_processed: true) }

      it 'not creates' do
        described_class.call(params)
        new_lead = EasyLead.find_by(b2b_external_id: params['id'].to_s)
        expect(new_lead).not_to be_nil

        expect(new_lead.easy_campaign).to eq(default_campaign)
      end
    end

    context 'with is_processed = true and campaign' do
      let(:external_campaign) { FactoryBot.create(:easy_campaign) }
      let(:internal_campaign) { FactoryBot.create(:easy_campaign, b2b_external_id: external_campaign.id) }
      let(:params) { lead_sample(is_processed: true, with_related_attributes: { external_campaign: external_campaign }) }

      it 'creates and connects campaign' do
        internal_campaign

        described_class.call(params)
        new_lead = EasyLead.find_by(b2b_external_id: params['id'].to_s)
        expect(new_lead).not_to be_nil

        expect(new_lead.easy_campaign.b2b_external_id).to eq(params['easy_campaign']['id'].to_s)
      end
    end

    context 'with related_attributes without campaign' do
      let(:external_attributes) { create_external_related_entities }
      let(:internal_attributes) { create_internal_related_entities(external_attributes) }
      let(:params) { lead_sample(is_processed: false, with_related_attributes: external_attributes) }

      it 'creates and connects related attributes' do
        internal_attributes

        described_class.call(params)
        new_lead = EasyLead.find_by(b2b_external_id: params['id'].to_s)
        expect(new_lead).not_to be_nil

        related_attributes.each do |name|
          next if name == 'easy_campaign' || name == 'easy_partner'

          if params[name]
            expect(new_lead.send(name).b2b_external_id).to eq(params[name]['id'].to_s)
          else
            expect(new_lead.send(name)).to be_nil
          end
        end
      end
    end

    context 'with blank related_attributes and without campaign' do
      let(:params) { lead_sample(is_processed: false) }

      it 'creates with nil related attributes' do
        described_class.call(params)
        new_lead = EasyLead.find_by(b2b_external_id: params['id'].to_s)
        expect(new_lead).not_to be_nil

        related_attributes.each do |name|
          next if name == 'easy_campaign' || name == 'easy_partner'

          expect(new_lead.send(name)).to be_nil
        end
      end
    end

    context '(with enumerations)' do
      let(:external_enums) { create_external_enumerations }
      let(:internal_enums) { create_internal_enumerations(external_enums) }
      let(:params) { lead_sample(is_processed: false, with_enums: external_enums) }

      it 'creates and connects enumerations' do
        internal_enums

        described_class.call(params)
        new_lead = EasyLead.find_by(b2b_external_id: params['id'].to_s)
        expect(new_lead).not_to be_nil

        enum_attributes.each do |name|
          if params[name]
            expect(new_lead.send(name).b2b_external_id).to eq(params[name]['id'].to_s)
          else
            expect(new_lead.send(name)).to be_nil
          end
        end
      end
    end

    context '(with enumeration attributes blank)' do
      let(:params) { lead_sample(is_processed: false) }

      it 'creates with nil enumerations' do
        described_class.call(params)
        new_lead = EasyLead.find_by(b2b_external_id: params['id'].to_s)
        expect(new_lead).not_to be_nil

        enum_attributes.each do |name|
          expect(new_lead.send(name)).to be_nil
        end
      end
    end

    context "(with custom fields)" do
      let(:external_cfs) { create_external_custom_fields }
      let(:internal_cfs) { create_internal_custom_fields(external_cfs) }
      let(:params) { lead_sample(is_processed: false, with_cfs: external_cfs) }

      it 'creates and connects custom fields' do
        internal_cfs

        described_class.call(params)
        new_lead = EasyLead.find_by(b2b_external_id: params['id'].to_s)
        expect(new_lead).not_to be_nil

        # Do leads have a separate logic?
        new_lead.custom_field_values.select { |cfv| internal_cfs.include?(cfv.custom_field) }.each do |cfv|
          expect(cfv.value).to eq(params['custom_fields'].find { |ocf| ocf['id'].to_s == cfv.custom_field.b2b_external_id }['value'])
        end
      end
    end
  end
end
