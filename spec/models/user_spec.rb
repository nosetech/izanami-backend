require 'rails_helper'

RSpec.describe User, type: :model do
  include FactoryBot::Syntax::Methods
  describe 'バリデーション' do
    let(:family) { create(:family) }
    
    it '名前、メールアドレス、パスワード、ロールがあれば有効である' do
      user = build(:user, family: family, name: 'テストユーザー', email: 'test@example.com', password: 'password', role: 'member')
      expect(user).to be_valid
    end

    it '名前がなければ無効である' do
      user = build(:user, family: family, name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("を入力してください")
    end

    it 'メールアドレスがなければ無効である' do
      user = build(:user, family: family, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("を入力してください")
    end

    it '重複したメールアドレスなら無効である' do
      create(:user, family: family, email: 'test@example.com')
      user = build(:user, family: family, email: 'test@example.com')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("はすでに存在します")
    end

    it 'パスワードがなければ無効である' do
      user = build(:user, family: family, password: nil)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("を入力してください")
    end

    it 'ロールがなければ無効である' do
      user = build(:user, family: family, role: nil)
      expect(user).not_to be_valid
      expect(user.errors[:role]).to include("を入力してください")
    end
  end

  describe 'アソシエーション' do
    it 'familyに紐付いている' do
      association = described_class.reflect_on_association(:family)
      expect(association.macro).to eq :belongs_to
    end
  end
end
