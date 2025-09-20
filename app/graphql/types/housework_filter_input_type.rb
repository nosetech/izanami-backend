module Types
  class HouseworkFilterInputType < Types::BaseInputObject
    argument :committed, Boolean, required: false, description: "Filter by committed status"
    argument :suggested_by_id, ID, required: false, description: "Filter by suggester user ID"
    argument :point_min, Integer, required: false, description: "Minimum point value"
    argument :point_max, Integer, required: false, description: "Maximum point value"
  end
end
