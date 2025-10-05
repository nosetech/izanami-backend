# frozen_string_literal: true

module Types
  class HouseworkCategoryEnum < Types::BaseEnum
    value "COOKING", "料理", value: "cooking"
    value "CLEANING", "掃除", value: "cleaning"
    value "SHOPPING", "買い物", value: "shopping"
    value "LAUNDRY", "洗濯", value: "laundry"
    value "OTHER", "その他", value: "other"
  end
end
