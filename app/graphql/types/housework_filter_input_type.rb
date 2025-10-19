module Types
  class HouseworkFilterInputType < Types::BaseInputObject
    argument :committed, Boolean, required: false, description: "Filter by committed status"
    argument :suggested_by_id, ID, required: false, description: "Filter by suggester user ID"
    argument :point_min, Integer, required: false, description: "Minimum point value"
    argument :point_max, Integer, required: false, description: "Maximum point value"
    argument :categories, [ Types::HouseworkCategoryEnum ], required: false, description: "Filter by categories (OR condition)"
    argument :keyword, String, required: false, description: "Keyword search for title and description (space-separated keywords with AND condition)"
  end
end
