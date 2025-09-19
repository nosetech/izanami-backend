FactoryBot.define do
  factory :housework do
    family
    association :suggested_by, factory: :user
    title { "掃除" }
    description { "リビングの掃除をする" }
    schedule { "毎週土曜日" }
    point { 10 }
    committed { false }
  end
end
