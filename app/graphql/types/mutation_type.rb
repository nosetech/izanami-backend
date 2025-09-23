# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    # Housework mutations
    field :create_housework, mutation: Mutations::CreateHouseworkMutation
    field :update_housework, mutation: Mutations::UpdateHouseworkMutation
    field :delete_housework, mutation: Mutations::DeleteHouseworkMutation

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World"
    end
  end
end
