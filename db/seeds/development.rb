# テーブルが空の場合のみSeedデータを投入する安全策を追加
if User.none?
  admin_family = Family.find_or_create_by!(name: '管理用ファミリー')

  admin_user = User.create!(
    name: 'システム管理者',
    email: 'admin@example.com',
    # パスワードは環境変数から取得、デフォルト値設定
    password: ENV.fetch('ADMIN_PASSWORD', 'password'),
    role: 'admin',
    family: admin_family
  )

  # サンプル家事データを追加
  sample_housework = Housework.create!(
    family: admin_family,
    suggested_by: admin_user,
    title: 'リビングの掃除',
    description: 'リビングルーム全体の掃除機がけと拭き掃除を行う',
    schedule: '毎週土曜日の午前中',
    point: 15,
    committed: false
  )

  puts "管理者ユーザーが作成されました: #{admin_user.email}"
  puts "サンプル家事データが作成されました: #{sample_housework.title}"
else
  puts "既にユーザーが存在するため、Seedデータは投入されませんでした"
end
