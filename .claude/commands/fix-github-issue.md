GitHub issueを分析して実行してください: issue番号 $ARGUMENTS

以下の手順で進めてください。

1. `gh issue view` で issue 詳細を取得
2. 問題の理解
3. 関連ファイルの検索
4. 修正の実装
5. gitコミットをする前に、bin/brakeman, bin/rubocopを実行する。エラーがあれば修正する。
6. gitコミット(developブランチに直接コミットしない。feature/\*ブランチにコミットすること)
7. developブランチにマージするgitプルリクエスト作成
