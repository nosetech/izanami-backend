require 'rails_helper'

RSpec.describe Housework, type: :model do
  include FactoryBot::Syntax::Methods

  describe 'バリデーション' do
    let(:family) { create(:family) }
    let(:user) { create(:user, family: family) }

    it 'タイトル、ファミリー、提案者があれば有効である' do
      housework = build(:housework, family: family, suggested_by: user, title: '掃除')
      expect(housework).to be_valid
    end

    it 'タイトルがなければ無効である' do
      housework = build(:housework, family: family, suggested_by: user, title: nil)
      expect(housework).not_to be_valid
      expect(housework.errors[:title]).to include("を入力してください")
    end

    it 'タイトルが200文字以内でなければ無効である' do
      housework = build(:housework, family: family, suggested_by: user, title: 'a' * 201)
      expect(housework).not_to be_valid
      expect(housework.errors[:title]).to include("は200文字以内で入力してください")
    end

    it '説明が500文字以内でなければ無効である' do
      housework = build(:housework, family: family, suggested_by: user, description: 'a' * 501)
      expect(housework).not_to be_valid
      expect(housework.errors[:description]).to include("は500文字以内で入力してください")
    end

    it 'スケジュールが100文字以内でなければ無効である' do
      housework = build(:housework, family: family, suggested_by: user, schedule: 'a' * 101)
      expect(housework).not_to be_valid
      expect(housework.errors[:schedule]).to include("は100文字以内で入力してください")
    end

    it 'ポイントがなければ無効である' do
      housework = build(:housework, family: family, suggested_by: user, point: nil)
      expect(housework).not_to be_valid
      expect(housework.errors[:point]).to include("を入力してください")
    end

    it 'ポイントが負の数なら無効である' do
      housework = build(:housework, family: family, suggested_by: user, point: -1)
      expect(housework).not_to be_valid
      expect(housework.errors[:point]).to include("は0以上の値にしてください")
    end

    it 'コミット済みフラグがnilなら無効である' do
      housework = build(:housework, family: family, suggested_by: user, committed: nil)
      expect(housework).not_to be_valid
      expect(housework.errors[:committed]).to include("は一覧にありません")
    end
  end

  describe 'アソシエーション' do
    it 'familyに紐付いている' do
      association = described_class.reflect_on_association(:family)
      expect(association.macro).to eq :belongs_to
    end

    it 'suggested_byに紐付いている' do
      association = described_class.reflect_on_association(:suggested_by)
      expect(association.macro).to eq :belongs_to
      expect(association.class_name).to eq 'User'
    end
  end

  describe 'スコープ' do
    let(:family) { create(:family) }
    let(:user) { create(:user, family: family) }
    let!(:active_housework) { create(:housework, family: family, suggested_by: user, deleted_at: nil) }
    let!(:deleted_housework) { create(:housework, family: family, suggested_by: user, deleted_at: Time.current) }
    let!(:committed_housework) { create(:housework, family: family, suggested_by: user, committed: true) }
    let!(:uncommitted_housework) { create(:housework, family: family, suggested_by: user, committed: false) }

    it 'activeスコープは削除されていない家事を返す' do
      expect(described_class.active).to include(active_housework)
      expect(described_class.active).not_to include(deleted_housework)
    end

    it 'committedスコープは承認済みの家事を返す' do
      expect(described_class.committed).to include(committed_housework)
      expect(described_class.committed).not_to include(uncommitted_housework)
    end

    it 'uncommittedスコープは未承認の家事を返す' do
      expect(described_class.uncommitted).to include(uncommitted_housework)
      expect(described_class.uncommitted).not_to include(committed_housework)
    end
  end
end
