class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :role, :family_id
end
