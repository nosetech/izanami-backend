# frozen_string_literal: true

module Mutations
  class UpdateHouseworkMutation < BaseMutation
    description "Updates an existing housework"

    argument :id, ID, required: true, description: "ID of the housework to update"
    argument :title, String, required: false, description: "Title of the housework"
    argument :description, String, required: false, description: "Description of the housework"
    argument :schedule, String, required: false, description: "Schedule information"
    argument :point, Integer, required: false, description: "Points for the housework (admin only)"
    argument :committed, Boolean, required: false, description: "Whether the housework is committed (admin only)"

    field :housework, Types::HouseworkType, null: true
    field :errors, [ String ], null: false

    def resolve(id:, **attributes)
      current_user = context[:current_user]

      unless current_user
        return {
          housework: nil,
          errors: [ "You must be logged in to update housework" ]
        }
      end

      housework = Housework.active.find_by(id: id)
      unless housework
        return {
          housework: nil,
          errors: [ "Housework not found" ]
        }
      end

      # Check if user belongs to the same family
      unless housework.family_id == current_user.family_id
        return {
          housework: nil,
          errors: [ "You can only update housework from your family" ]
        }
      end

      # Check if housework is committed and cannot be updated (except for admins)
      if housework.committed? && current_user.role != "admin"
        return {
          housework: nil,
          errors: [ "Cannot update committed housework" ]
        }
      end

      # Check authorization: owner or admin can update
      unless current_user.role == "admin" || housework.suggested_by_id == current_user.id
        return {
          housework: nil,
          errors: [ "You can only update housework you created or must be an administrator" ]
        }
      end

      # Only admins can set point and committed fields
      if (attributes[:point].present? || attributes[:committed].present?) && current_user.role != "admin"
        return {
          housework: nil,
          errors: [ "Only administrators can set point and committed fields" ]
        }
      end

      # Filter out nil values to only update provided attributes
      update_attributes = attributes.compact

      if housework.update(update_attributes)
        {
          housework: housework,
          errors: []
        }
      else
        {
          housework: nil,
          errors: housework.errors.full_messages
        }
      end
    end
  end
end
