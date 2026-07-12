# 品質チェック

## 方針

- チェック項目、レビュー観点、既知リスクの扱いを定義します。
- 自動化可能な項目は順次 CI に移行します。

## ドキュメント拡張方針

- `sphinxcontrib.blockdiag` 系は既存資産互換のため当面維持します。
- `pkg_resources` 警告は `docs/source/conf.py` で抑制し、`docs/requirements.txt` の `setuptools<81` で RTD ビルド互換を確保します。
- 将来的な拡張置換は、図版資産の移行工数を見積もった上で段階実施します。
