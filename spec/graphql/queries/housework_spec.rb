require 'rails_helper'

RSpec.describe 'Housework GraphQL Queries', type: :request do
  include FactoryBot::Syntax::Methods

  let(:family) { create(:family) }
  let(:user) { create(:user, family: family) }
  let(:other_family) { create(:family) }
  let(:other_user) { create(:user, family: other_family) }
  let!(:housework1) { create(:housework, family: family, suggested_by: user, title: '掃除', point: 10, committed: false, created_at: 2.days.ago) }
  let!(:housework2) { create(:housework, family: family, suggested_by: user, title: '洗濯', point: 5, committed: true, created_at: 1.day.ago) }
  let!(:housework3) { create(:housework, family: family, suggested_by: user, title: '料理', point: 15, committed: false, created_at: 3.days.ago) }
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
        query($familyId: ID!, $filter: HouseworkFilterInput, $sort: HouseworkSortInput, $first: Int, $after: String) {
          houseworks(familyId: $familyId, filter: $filter, sort: $sort, first: $first, after: $after) {
            edges {
              node {
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
              cursor
            }
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
          }
        }
      GRAPHQL
    end

    context 'when user is in the same family' do
      it 'returns all houseworks for the family' do
        result = execute_query(query, variables: { familyId: family.id }, context: { current_user: user })

        expect(result['errors']).to be_nil
        data = result['data']['houseworks']
        expect(data['edges'].length).to eq(3)
        titles = data['edges'].map { |edge| edge['node']['title'] }
        expect(titles).to contain_exactly('掃除', '洗濯', '料理')
      end

      context 'with committed filter' do
        it 'returns only committed houseworks' do
          result = execute_query(query,
            variables: { familyId: family.id, filter: { committed: true } },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to eq(1)
          expect(data['edges'][0]['node']['title']).to eq('洗濯')
          expect(data['edges'][0]['node']['committed']).to eq(true)
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
          expect(data['edges'].length).to eq(3)
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
          expect(data['edges'].length).to eq(2)
          titles = data['edges'].map { |edge| edge['node']['title'] }
          expect(titles).to contain_exactly('掃除', '料理')
        end
      end

      context 'with sort parameter' do
        it 'sorts houseworks by title in ascending order' do
          result = execute_query(query,
            variables: { familyId: family.id, sort: { field: 'title', direction: 'asc' } },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to eq(3)
          titles = data['edges'].map { |edge| edge['node']['title'] }
          expect(titles).to eq([ '掃除', '料理', '洗濯' ])
        end

        it 'sorts houseworks by title in descending order' do
          result = execute_query(query,
            variables: { familyId: family.id, sort: { field: 'title', direction: 'desc' } },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to eq(3)
          titles = data['edges'].map { |edge| edge['node']['title'] }
          expect(titles).to eq([ '洗濯', '料理', '掃除' ])
        end

        it 'sorts houseworks by point in ascending order' do
          result = execute_query(query,
            variables: { familyId: family.id, sort: { field: 'point', direction: 'asc' } },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to eq(3)
          points = data['edges'].map { |edge| edge['node']['point'] }
          expect(points).to eq([ 5, 10, 15 ])
        end

        it 'sorts houseworks by point in descending order' do
          result = execute_query(query,
            variables: { familyId: family.id, sort: { field: 'point', direction: 'desc' } },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to eq(3)
          points = data['edges'].map { |edge| edge['node']['point'] }
          expect(points).to eq([ 15, 10, 5 ])
        end

        it 'sorts houseworks by created_at in ascending order' do
          result = execute_query(query,
            variables: { familyId: family.id, sort: { field: 'created_at', direction: 'asc' } },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to eq(3)
          titles = data['edges'].map { |edge| edge['node']['title'] }
          expect(titles).to eq([ '料理', '掃除', '洗濯' ])
        end

        it 'sorts houseworks by created_at in descending order' do
          result = execute_query(query,
            variables: { familyId: family.id, sort: { field: 'created_at', direction: 'desc' } },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to eq(3)
          titles = data['edges'].map { |edge| edge['node']['title'] }
          expect(titles).to eq([ '洗濯', '掃除', '料理' ])
        end

        it 'defaults to ascending order when direction is not specified' do
          result = execute_query(query,
            variables: { familyId: family.id, sort: { field: 'point' } },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to eq(3)
          points = data['edges'].map { |edge| edge['node']['point'] }
          expect(points).to eq([ 5, 10, 15 ])
        end

        it 'ignores invalid field names' do
          result = execute_query(query,
            variables: { familyId: family.id, sort: { field: 'invalid_field', direction: 'asc' } },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to eq(3)
        end

        it 'ignores invalid direction values' do
          result = execute_query(query,
            variables: { familyId: family.id, sort: { field: 'point', direction: 'invalid' } },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to eq(3)
        end
      end

      context 'with pagination parameters' do
        let!(:housework4) { create(:housework, family: family, suggested_by: user, title: 'ゴミ出し', point: 3, committed: false, created_at: 4.days.ago) }
        let!(:housework5) { create(:housework, family: family, suggested_by: user, title: '買い物', point: 8, committed: true, created_at: 5.days.ago) }

        it 'returns limited number of houseworks with first parameter' do
          result = execute_query(query,
            variables: { familyId: family.id, first: 2 },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to eq(2)
          expect(data['pageInfo']['hasNextPage']).to eq(true)
          expect(data['pageInfo']['startCursor']).not_to be_nil
          expect(data['pageInfo']['endCursor']).not_to be_nil
        end

        it 'returns next page with after parameter' do
          first_result = execute_query(query,
            variables: { familyId: family.id, first: 2 },
            context: { current_user: user }
          )
          end_cursor = first_result['data']['houseworks']['pageInfo']['endCursor']

          result = execute_query(query,
            variables: { familyId: family.id, first: 2, after: end_cursor },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to be <= 2
          expect(data['pageInfo']['hasPreviousPage']).to eq(true)
        end

        it 'indicates no next page when at the end' do
          result = execute_query(query,
            variables: { familyId: family.id, first: 10 },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['pageInfo']['hasNextPage']).to eq(false)
        end

        it 'works with sorting and pagination combined' do
          result = execute_query(query,
            variables: {
              familyId: family.id,
              first: 3,
              sort: { field: 'point', direction: 'desc' }
            },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to eq(3)
          points = data['edges'].map { |edge| edge['node']['point'] }
          expect(points).to eq([ 15, 10, 8 ])
        end

        it 'works with filtering and pagination combined' do
          result = execute_query(query,
            variables: {
              familyId: family.id,
              first: 2,
              filter: { committed: false }
            },
            context: { current_user: user }
          )

          expect(result['errors']).to be_nil
          data = result['data']['houseworks']
          expect(data['edges'].length).to eq(2)
          data['edges'].each do |edge|
            expect(edge['node']['committed']).to eq(false)
          end
        end
      end
    end

    context 'when user is not in the same family' do
      it 'returns empty array' do
        result = execute_query(query, variables: { familyId: other_family.id }, context: { current_user: user })

        expect(result['errors']).to be_nil
        expect(result['data']['houseworks']['edges']).to eq([])
      end
    end

    context 'when user is not authenticated' do
      it 'returns empty array' do
        result = execute_query(query, variables: { familyId: family.id })

        expect(result['errors']).to be_nil
        expect(result['data']['houseworks']['edges']).to eq([])
      end
    end
  end
end
