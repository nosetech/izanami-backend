FactoryBot.define do
  factory :user do
    family
    name { "テストユーザー" }
    sequence(:email) { |n| "test#{n}@example.com" }
    password { "password" }
    role { "member" }
  end
end
