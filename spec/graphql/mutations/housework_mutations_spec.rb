require 'rails_helper'

RSpec.describe 'Housework GraphQL Mutations', type: :request do
  include FactoryBot::Syntax::Methods

  let(:family) { create(:family) }
  let(:admin_user) { create(:user, family: family, role: :admin) }
  let(:member_user) { create(:user, family: family, role: :member) }
  let(:guest_user) { create(:user, family: family, role: :guest) }
  let(:other_family) { create(:family) }
  let(:other_user) { create(:user, family: other_family, role: :member) }
  let(:user_without_family) { create(:user, family: nil) }

  def execute_mutation(mutation_string, variables: {}, context: {})
    IzanamiBackendSchema.execute(mutation_string, variables: variables, context: context)
  end

  describe 'createHousework mutation' do
    let(:mutation) do
      <<~GRAPHQL
        mutation($title: String!, $description: String, $schedule: String, $point: Int, $committed: Boolean) {
          createHousework(input: {
            title: $title,
            description: $description,
            schedule: $schedule,
            point: $point,
            committed: $committed
          }) {
            housework {
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
            }
            errors
          }
        }
      GRAPHQL
    end

    context 'when user is authenticated and has a family' do
      context 'as a member user' do
        it 'creates housework with basic fields' do
          variables = {
            title: '新しい掃除',
            description: 'テスト用の掃除',
            schedule: '毎日'
          }

          result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

          expect(result['errors']).to be_nil
          data = result['data']['createHousework']
          expect(data['errors']).to be_empty
          expect(data['housework']).not_to be_nil
          expect(data['housework']['title']).to eq('新しい掃除')
          expect(data['housework']['description']).to eq('テスト用の掃除')
          expect(data['housework']['schedule']).to eq('毎日')
          expect(data['housework']['familyId']).to eq(family.id)
          expect(data['housework']['suggestedBy']['id']).to eq(member_user.id)
          expect(data['housework']['point']).to eq(0)
          expect(data['housework']['committed']).to eq(false)
        end

        it 'cannot set point and committed fields' do
          variables = {
            title: '新しい掃除',
            point: 20,
            committed: true
          }

          result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

          expect(result['errors']).to be_nil
          data = result['data']['createHousework']
          expect(data['errors']).to include('Only administrators can set point and committed fields')
          expect(data['housework']).to be_nil
        end
      end

      context 'as an admin user' do
        it 'creates housework with all fields including point and committed' do
          variables = {
            title: '管理者の掃除',
            description: '管理者が作成',
            point: 25,
            committed: true
          }

          result = execute_mutation(mutation, variables: variables, context: { current_user: admin_user })

          expect(result['errors']).to be_nil
          data = result['data']['createHousework']
          expect(data['errors']).to be_empty
          expect(data['housework']).not_to be_nil
          expect(data['housework']['title']).to eq('管理者の掃除')
          expect(data['housework']['point']).to eq(25)
          expect(data['housework']['committed']).to eq(true)
        end
      end
    end

    context 'when user is not authenticated' do
      it 'returns authentication error' do
        variables = { title: '認証なし掃除' }

        result = execute_mutation(mutation, variables: variables)

        expect(result['errors']).to be_nil
        data = result['data']['createHousework']
        expect(data['errors']).to include('You must be logged in to create housework')
        expect(data['housework']).to be_nil
      end
    end

    context 'when user has no family' do
      it 'returns family assignment error' do
        variables = { title: 'ファミリーなし掃除' }

        result = execute_mutation(mutation, variables: variables, context: { current_user: user_without_family })

        expect(result['errors']).to be_nil
        data = result['data']['createHousework']
        expect(data['errors']).to include('You must be assigned to a family to create housework')
        expect(data['housework']).to be_nil
      end
    end

    context 'with invalid data' do
      it 'returns validation errors for missing title' do
        variables = { title: '', description: '説明のみ' }

        result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

        expect(result['errors']).to be_nil
        data = result['data']['createHousework']
        expect(data['errors']).to include("タイトル を入力してください")
        expect(data['housework']).to be_nil
      end
    end
  end

  describe 'updateHousework mutation' do
    let!(:housework) { create(:housework, family: family, suggested_by: member_user, title: 'Original Title', point: 10, committed: false) }
    let!(:committed_housework) { create(:housework, family: family, suggested_by: member_user, title: 'Committed Work', committed: true) }
    let!(:other_user_housework) { create(:housework, family: family, suggested_by: admin_user, title: 'Admin Work') }

    let(:mutation) do
      <<~GRAPHQL
        mutation($id: ID!, $title: String, $description: String, $schedule: String, $point: Int, $committed: Boolean) {
          updateHousework(input: {
            id: $id,
            title: $title,
            description: $description,
            schedule: $schedule,
            point: $point,
            committed: $committed
          }) {
            housework {
              id
              title
              description
              schedule
              point
              committed
            }
            errors
          }
        }
      GRAPHQL
    end

    context 'when updating own housework' do
      context 'as the owner' do
        it 'updates the housework successfully' do
          variables = {
            id: housework.id,
            title: 'Updated Title',
            description: 'Updated Description'
          }

          result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

          expect(result['errors']).to be_nil
          data = result['data']['updateHousework']
          expect(data['errors']).to be_empty
          expect(data['housework']['title']).to eq('Updated Title')
          expect(data['housework']['description']).to eq('Updated Description')
        end

        it 'cannot set admin-only fields' do
          variables = {
            id: housework.id,
            title: 'Updated Title',
            point: 50,
            committed: true
          }

          result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

          expect(result['errors']).to be_nil
          data = result['data']['updateHousework']
          expect(data['errors']).to include('Only administrators can set point and committed fields')
          expect(data['housework']).to be_nil
        end

        it 'cannot update committed housework' do
          variables = {
            id: committed_housework.id,
            title: 'Trying to Update Committed'
          }

          result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

          expect(result['errors']).to be_nil
          data = result['data']['updateHousework']
          expect(data['errors']).to include('Cannot update committed housework')
          expect(data['housework']).to be_nil
        end
      end

      context 'as admin' do
        it 'can update any housework with all fields' do
          variables = {
            id: housework.id,
            title: 'Admin Updated Title',
            point: 100,
            committed: true
          }

          result = execute_mutation(mutation, variables: variables, context: { current_user: admin_user })

          expect(result['errors']).to be_nil
          data = result['data']['updateHousework']
          expect(data['errors']).to be_empty
          expect(data['housework']['title']).to eq('Admin Updated Title')
          expect(data['housework']['point']).to eq(100)
          expect(data['housework']['committed']).to eq(true)
        end

        it 'cannot update committed housework even as admin' do
          variables = {
            id: committed_housework.id,
            title: 'Admin Trying to Update Committed'
          }

          result = execute_mutation(mutation, variables: variables, context: { current_user: admin_user })

          expect(result['errors']).to be_nil
          data = result['data']['updateHousework']
          expect(data['errors']).to include('Cannot update committed housework')
          expect(data['housework']).to be_nil
        end
      end
    end

    context 'when updating other user\'s housework' do
      it 'returns authorization error for non-admin' do
        variables = {
          id: other_user_housework.id,
          title: 'Unauthorized Update'
        }

        result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

        expect(result['errors']).to be_nil
        data = result['data']['updateHousework']
        expect(data['errors']).to include('You can only update housework you created or must be an administrator')
        expect(data['housework']).to be_nil
      end
    end

    context 'when user is not authenticated' do
      it 'returns authentication error' do
        variables = { id: housework.id, title: 'Unauthenticated Update' }

        result = execute_mutation(mutation, variables: variables)

        expect(result['errors']).to be_nil
        data = result['data']['updateHousework']
        expect(data['errors']).to include('You must be logged in to update housework')
        expect(data['housework']).to be_nil
      end
    end

    context 'when housework doesn\'t exist' do
      it 'returns not found error' do
        variables = { id: 'non-existent-id', title: 'Update Nothing' }

        result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

        expect(result['errors']).to be_nil
        data = result['data']['updateHousework']
        expect(data['errors']).to include('Housework not found')
        expect(data['housework']).to be_nil
      end
    end

    context 'when housework is from different family' do
      let!(:other_family_housework) { create(:housework, family: other_family, suggested_by: other_user) }

      it 'returns family restriction error' do
        variables = { id: other_family_housework.id, title: 'Cross Family Update' }

        result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

        expect(result['errors']).to be_nil
        data = result['data']['updateHousework']
        expect(data['errors']).to include('You can only update housework from your family')
        expect(data['housework']).to be_nil
      end
    end
  end

  describe 'deleteHousework mutation' do
    let!(:housework) { create(:housework, family: family, suggested_by: member_user, title: 'To Delete', committed: false) }
    let!(:committed_housework) { create(:housework, family: family, suggested_by: member_user, title: 'Committed Work', committed: true) }
    let!(:other_user_housework) { create(:housework, family: family, suggested_by: admin_user, title: 'Admin Work') }

    let(:mutation) do
      <<~GRAPHQL
        mutation($id: ID!) {
          deleteHousework(input: { id: $id }) {
            success
            errors
          }
        }
      GRAPHQL
    end

    context 'when deleting own housework' do
      it 'soft deletes the housework successfully' do
        variables = { id: housework.id }

        result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

        expect(result['errors']).to be_nil
        data = result['data']['deleteHousework']
        expect(data['errors']).to be_empty
        expect(data['success']).to eq(true)

        # Verify soft delete
        housework.reload
        expect(housework.deleted_at).not_to be_nil
      end

      it 'cannot delete committed housework' do
        variables = { id: committed_housework.id }

        result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

        expect(result['errors']).to be_nil
        data = result['data']['deleteHousework']
        expect(data['errors']).to include('Cannot delete committed housework')
        expect(data['success']).to eq(false)
      end
    end

    context 'as admin' do
      it 'can delete any non-committed housework' do
        variables = { id: housework.id }

        result = execute_mutation(mutation, variables: variables, context: { current_user: admin_user })

        expect(result['errors']).to be_nil
        data = result['data']['deleteHousework']
        expect(data['errors']).to be_empty
        expect(data['success']).to eq(true)

        # Verify soft delete
        housework.reload
        expect(housework.deleted_at).not_to be_nil
      end

      it 'cannot delete committed housework even as admin' do
        variables = { id: committed_housework.id }

        result = execute_mutation(mutation, variables: variables, context: { current_user: admin_user })

        expect(result['errors']).to be_nil
        data = result['data']['deleteHousework']
        expect(data['errors']).to include('Cannot delete committed housework')
        expect(data['success']).to eq(false)
      end
    end

    context 'when deleting other user\'s housework' do
      it 'returns authorization error for non-admin' do
        variables = { id: other_user_housework.id }

        result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

        expect(result['errors']).to be_nil
        data = result['data']['deleteHousework']
        expect(data['errors']).to include('You can only delete housework you created or must be an administrator')
        expect(data['success']).to eq(false)
      end
    end

    context 'when user is not authenticated' do
      it 'returns authentication error' do
        variables = { id: housework.id }

        result = execute_mutation(mutation, variables: variables)

        expect(result['errors']).to be_nil
        data = result['data']['deleteHousework']
        expect(data['errors']).to include('You must be logged in to delete housework')
        expect(data['success']).to eq(false)
      end
    end

    context 'when housework doesn\'t exist' do
      it 'returns not found error' do
        variables = { id: 'non-existent-id' }

        result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

        expect(result['errors']).to be_nil
        data = result['data']['deleteHousework']
        expect(data['errors']).to include('Housework not found')
        expect(data['success']).to eq(false)
      end
    end

    context 'when housework is from different family' do
      let!(:other_family_housework) { create(:housework, family: other_family, suggested_by: other_user) }

      it 'returns family restriction error' do
        variables = { id: other_family_housework.id }

        result = execute_mutation(mutation, variables: variables, context: { current_user: member_user })

        expect(result['errors']).to be_nil
        data = result['data']['deleteHousework']
        expect(data['errors']).to include('You can only delete housework from your family')
        expect(data['success']).to eq(false)
      end
    end
  end
end
