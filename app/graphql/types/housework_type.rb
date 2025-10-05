module Types
  class HouseworkType < Types::BaseObject
    field :id, ID, null: false
    field :family_id, ID, null: false
    field :title, String, null: false
    field :description, String, null: true
    field :schedule, String, null: true
    field :suggested_by, Types::UserType, null: false
    field :point, Integer, null: false
    field :committed, Boolean, null: false
    field :category, Types::HouseworkCategoryEnum, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
