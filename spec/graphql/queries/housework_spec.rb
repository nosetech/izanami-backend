require 'rails_helper'

RSpec.describe 'Housework GraphQL Queries', type: :request do
  include FactoryBot::Syntax::Methods

  let(:family) { create(:family) }
  let(:user) { create(:user, family: family) }
  let(:other_family) { create(:family) }
  let(:other_user) { create(:user, family: other_family) }
  let!(:housework1) { create(:housework, family: family, suggested_by: user, title: '掃除', point: 10, committed: false) }
  let!(:housework2) { create(:housework, family: family, suggested_by: user, title: '洗濯', point: 5, committed: true) }
  let!(:other_housework) { create(:housework, family: other_family, suggested_by: other_user) }

  def execute_query(query_string, variables: {}, context: {})
    IzanamiBackendSchema.execute(query_string, variables: variables, context: context)
  end

  describe 'housework query' do
    let(:query) do
      <<~GRAPHQL
        query($id: ID!) {
          housework(id: $id) {
            id
            familyId
            title
            description
            schedule
            suggestedBy {
              id
              name
            }
            point
            committed
            createdAt
            updatedAt
          }
        }
      GRAPHQL
    end

    context 'when user is in the same family' do
      it 'returns the housework' do
        result = execute_query(query, variables: { id: housework1.id }, context: { current_user: user })

        expect(result['errors']).to be_nil
        data = result['data']['housework']
        expect(data['id']).to eq(housework1.id)
        expect(data['title']).to eq('掃除')
        expect(data['point']).to eq(10)
        expect(data['committed']).to eq(false)
        expect(data['suggestedBy']['id']).to eq(user.id)
      end
    end

    context 'when user is not in the same family' do
      it 'returns null' do
        result = execute_query(query, variables: { id: other_housework.id }, context: { current_user: user })

        expect(result['errors']).to be_nil
        expect(result['data']['housework']).to be_nil
      end
    end

    context 'when user is not authenticated' do
      it 'returns null' do
        result = execute_query(query, variables: { id: housework1.id })

        expect(result['errors']).to be_nil
        expect(result['data']['housework']).to be_nil
      end
    end

    context 'when housework is deleted' do
      it 'returns null' do
        housework1.update!(deleted_at: Time.current)
        result = execute_query(query, variables: { id: housework1.id }, context: { current_user: user })

        expect(result['errors']).to be_nil
        expect(result['data']['housework']).to be_nil
      end
    end
  end

  describe 'houseworks query' do
    let(:query) do
      <<~GRAPHQL
        query($familyId: ID!, $filter: HouseworkFilterInput) {
          houseworks(familyId: $familyId, filter: $filter) {
            id
            title
            description
            schedule
            suggestedBy {
              id
              name
            }
            point
            committed
            createdAt
            updatedAt
          }
        }
      GRAPHQL
    end

    context 'when user is in the same family' do
      it 'returns all houseworks for the family' do
        result = execute_query(query, variables: { familyId: family.id }, context: { current_user: user })

        expect(result['errors']).to be_nil
        data = result['data']['houseworks']
        expect(data.length).to eq(2)
        titles = data.map { |h| h['title'] }
        expect(titles).to contain_exactly('掃除', '洗濯')
      end

      context 'with committed filter' do
        it 'returns only committed houseworks' do
          result = execute_query(query,
            variables: { familyId: family.id, filter: { committed: true } },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data.length).to eq(1)
          expect(data[0]['title']).to eq('洗濯')
          expect(data[0]['committed']).to eq(true)
        end
      end

      context 'with suggested_by filter' do
        it 'returns houseworks suggested by the specified user' do
          result = execute_query(query,
            variables: { familyId: family.id, filter: { suggestedById: user.id } },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data.length).to eq(2)
        end
      end

      context 'with point range filter' do
        it 'returns houseworks within the point range' do
          result = execute_query(query,
            variables: { familyId: family.id, filter: { pointMin: 8 } },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data.length).to eq(1)
          expect(data[0]['title']).to eq('掃除')
          expect(data[0]['point']).to eq(10)
        end
      end
    end

    context 'when user is not in the same family' do
      it 'returns empty array' do
        result = execute_query(query, variables: { familyId: other_family.id }, context: { current_user: user })

        expect(result['errors']).to be_nil
        expect(result['data']['houseworks']).to eq([])
      end
    end

    context 'when user is not authenticated' do
      it 'returns empty array' do
        result = execute_query(query, variables: { familyId: family.id })

        expect(result['errors']).to be_nil
        expect(result['data']['houseworks']).to eq([])
      end
    end
  end
end
