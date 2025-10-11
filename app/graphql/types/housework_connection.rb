# frozen_string_literal: true

module Types
  class HouseworkConnection < Types::BaseConnection
    edge_type(Types::HouseworkType.edge_type)

    field :total_count, Integer, null: false, description: "Total number of houseworks matching the filter criteria"

    def total_count
      object.items.size
    end
  end
end
