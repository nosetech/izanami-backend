# frozen_string_literal: true

module Mutations
  class CreateHouseworkMutation < BaseMutation
    description "Creates a new housework"

    argument :title, String, required: true, description: "Title of the housework"
    argument :description, String, required: false, description: "Description of the housework"
    argument :schedule, String, required: false, description: "Schedule information"
    argument :point, Integer, required: false, description: "Points for the housework (admin only)"
    argument :committed, Boolean, required: false, description: "Whether the housework is committed (admin only)"

    field :housework, Types::HouseworkType, null: true
    field :errors, [ String ], null: false

    def resolve(title:, description: nil, schedule: nil, point: nil, committed: nil)
      current_user = context[:current_user]

      unless current_user
        return {
          housework: nil,
          errors: [ "You must be logged in to create housework" ]
        }
      end

      unless current_user.family_id
        return {
          housework: nil,
          errors: [ "You must be assigned to a family to create housework" ]
        }
      end

      # Only admins can set point and committed fields
      if (point.present? || committed.present?) && current_user.role != "admin"
        return {
          housework: nil,
          errors: [ "Only administrators can set point and committed fields" ]
        }
      end

      # Set default values for admin-only fields
      point = 0 if point.nil?
      committed = false if committed.nil?

      housework = Housework.new(
        family_id: current_user.family_id,
        title: title,
        description: description,
        schedule: schedule,
        suggested_by: current_user,
        point: point,
        committed: committed
      )

      if housework.save
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
