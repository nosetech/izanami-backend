# テーブルが空の場合のみSeedデータを投入する安全策を追加
if User.none?
  admin_user = User.create!(
    name: 'システム管理者',
    email: 'admin@example.com',
    # パスワードは環境変数から取得、デフォルト値設定
    password: ENV.fetch('ADMIN_PASSWORD', 'password'),
    role: 'admin',
    family: Family.find_or_create_by!(name: '管理用ファミリー')
  )

  puts "管理者ユーザーが作成されました: #{admin_user.email}"
else
  puts "既にユーザーが存在するため、Seedデータは投入されませんでした"
end
