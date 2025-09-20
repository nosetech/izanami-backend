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

    field :houseworks, [ Types::HouseworkType ], null: false do
      argument :family_id, ID, required: true, description: "ID of the family"
      argument :filter, Types::HouseworkFilterInputType, required: false, description: "Filter options"
    end

    def housework(id:)
      user = context[:current_user]
      return nil unless user

      begin
        housework_obj = GlobalID.find(id)
        return nil unless housework_obj.is_a?(Housework)
        return nil if housework_obj.deleted_at.present?
        return nil unless housework_obj.family_id == user.family_id
        housework_obj
      rescue ActiveRecord::RecordNotFound, URI::GID::MissingModelIdError
        nil
      end
    end

    def houseworks(family_id:, filter: nil)
      user = context[:current_user]
      return [] unless user

      begin
        family_obj = GlobalID.find(family_id)
        return [] unless family_obj.is_a?(Family)
        return [] unless family_obj.id == user.family_id
      rescue ActiveRecord::RecordNotFound, URI::GID::MissingModelIdError
        return []
      end

      houseworks = Housework.active.where(family_id: family_obj.id)

      if filter
        houseworks = houseworks.where(committed: filter[:committed]) unless filter[:committed].nil?
        if filter[:suggested_by_id].present?
          begin
            suggested_by_obj = GlobalID.find(filter[:suggested_by_id])
            houseworks = houseworks.where(suggested_by_id: suggested_by_obj.id) if suggested_by_obj.is_a?(User)
          rescue ActiveRecord::RecordNotFound, URI::GID::MissingModelIdError
            # Invalid suggested_by_id, ignore this filter
          end
        end
        houseworks = houseworks.where(point: filter[:point_min]..) if filter[:point_min].present?
        houseworks = houseworks.where(point: ..filter[:point_max]) if filter[:point_max].present?
      end

      houseworks
    end
  end
end
