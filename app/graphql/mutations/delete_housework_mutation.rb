# frozen_string_literal: true

module Mutations
  class DeleteHouseworkMutation < BaseMutation
    description "Deletes an existing housework (soft delete)"

    argument :id, ID, required: true, description: "ID of the housework to delete"

    field :success, Boolean, null: false
    field :errors, [ String ], null: false

    def resolve(id:)
      current_user = context[:current_user]

      unless current_user
        return {
          success: false,
          errors: [ "You must be logged in to delete housework" ]
        }
      end

      housework = Housework.active.find_by(id: id)
      unless housework
        return {
          success: false,
          errors: [ "Housework not found" ]
        }
      end

      # Check if user belongs to the same family
      unless housework.family_id == current_user.family_id
        return {
          success: false,
          errors: [ "You can only delete housework from your family" ]
        }
      end

      # Check if housework is committed and cannot be deleted
      if housework.committed?
        return {
          success: false,
          errors: [ "Cannot delete committed housework" ]
        }
      end

      # Check authorization: owner or admin can delete
      unless current_user.role == "admin" || housework.suggested_by_id == current_user.id
        return {
          success: false,
          errors: [ "You can only delete housework you created or must be an administrator" ]
        }
      end

      # Soft delete by setting deleted_at timestamp
      if housework.update(deleted_at: Time.current)
        {
          success: true,
          errors: []
        }
      else
        {
          success: false,
          errors: housework.errors.full_messages
        }
      end
    end
  end
end
