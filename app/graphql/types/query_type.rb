# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [ Types::NodeType, null: true ], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ ID ], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.
    field :users, [ Types::UserType ], null: false, description: "Returns a list of active users"
    field :user, Types::UserType, null: true do
      argument :id, ID, required: true, description: "ID of the user"
    end

    def users
      User.active
    end

    def user(id:)
      User.active.find_by(id: id)
    end

    field :families, [ Types::FamilyType ], null: false, description: "Returns a list of families"
    field :family, Types::FamilyType, null: true do
      argument :id, ID, required: true, description: "ID of the family"
    end

    def families
      Family.active
    end

    def family(id:)
      Family.active.find_by(id: id)
    end

    field :housework, Types::HouseworkType, null: true do
      argument :id, ID, required: true, description: "ID of the housework"
    end

    field :houseworks, Types::HouseworkConnection, null: false, connection: true do
      argument :family_id, ID, required: true, description: "ID of the family"
      argument :filter, Types::HouseworkFilterInputType, required: false, description: "Filter options"
      argument :sort, Types::HouseworkSortInputType, required: false, description: "Sort options"
    end

    def housework(id:)
      user = context[:current_user]
      return nil unless user

      housework = Housework.active.find_by(id: id)
      return nil unless housework
      return nil unless housework.family_id == user.family_id

      housework
    end

    def houseworks(family_id:, filter: nil, sort: nil)
      user = context[:current_user]
      return [] unless user
      return [] unless user.family_id == family_id

      houseworks = Housework.active.where(family_id: family_id)

      if filter
        houseworks = houseworks.where(committed: filter[:committed]) unless filter[:committed].nil?
        houseworks = houseworks.where(suggested_by_id: filter[:suggested_by_id]) if filter[:suggested_by_id].present?
        houseworks = houseworks.where(point: filter[:point_min]..) if filter[:point_min].present?
        houseworks = houseworks.where(point: ..filter[:point_max]) if filter[:point_max].present?
        houseworks = houseworks.where(category: filter[:categories]) if filter[:categories].present?
      end

      if sort
        field = sort[:field]
        direction = sort[:direction] || "asc"

        valid_fields = %w[title point created_at updated_at]
        valid_directions = %w[asc desc]

        if valid_fields.include?(field) && valid_directions.include?(direction)
          houseworks = houseworks.order("#{field} #{direction}")
        end
      end

      houseworks
    end
  end
end
