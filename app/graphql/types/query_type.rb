# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.
    field :users, [Types::UserType], null: false, description: "Returns a list of active users"
    field :user, Types::UserType, null: true do
      argument :id, ID, required: true, description: "ID of the user"
    end

    def users
      User.active
    end

    def user(id:)
      User.active.find_by(id: id)
    end
 
    field :families, [Types::FamilyType], null: false, description: "Returns a list of families"
    field :family, Types::FamilyType, null: true do
      argument :id, ID, required: true, description: "ID of the family"
    end

    def families
      Family.active
    end

    def family(id:)
      Family.active.find_by(id: id)
    end

  end
end
