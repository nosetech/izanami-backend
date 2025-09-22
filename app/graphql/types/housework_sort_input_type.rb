module Types
  class HouseworkSortInputType < Types::BaseInputObject
    argument :field, String, required: true, description: "Field to sort by (title, point, created_at, updated_at)"
    argument :direction, String, required: false, description: "Sort direction (asc or desc)", default_value: "asc"
  end
end
