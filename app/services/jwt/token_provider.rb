module Jwt
  module TokenProvider
    extend self

    def call(user_id)
      issue_token(user_id)
    end

    private

    def issue_token(user_id)
      # TODO: JWT有効期限を設定ファイルで定義できるようにする。
      JWT.encode({ user_id:, exp: (DateTime.current + 14.days).to_i }, Rails.application.credentials.secret_key_base)
    end
  end
end
