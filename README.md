# 簡易電卓 PWA (ExternalIntegrationSamples)

静的ホスティング可能な電卓 Web アプリです。PWA 対応（オフライン/ホーム画面追加）済み。

## 構成
- `index.html` 本体
- `sw.js` Service Worker（キャッシュ戦略: ナビゲーションはネットワーク優先/フォールバック、静的は Stale-While-Revalidate）
- `manifest.webmanifest` PWA マニフェスト
- `offline.html` オフライン時のフォールバックページ
- `icons/Generate-CalculatorIcons.ps1` アイコン生成スクリプト（Windows PowerShell 用）
- `icons/icon-192.png`, `icons/icon-512.png` は未生成（スクリプトで生成）

## アイコン生成（Windows）
PowerShell 7 以上での実行例:
```powershell
pwsh -ExecutionPolicy Bypass -File .\icons\Generate-CalculatorIcons.ps1
```
Windows PowerShell 5.1 の実行例:
```powershell
powershell -ExecutionPolicy Bypass -File .\icons\Generate-CalculatorIcons.ps1
```
生成後、`manifest.webmanifest` の参照パス（`./icons/icon-192.png`, `./icons/icon-512.png`）で使用されます。

## ローカルプレビュー
任意の静的サーバを使用してください。例（PowerShell / Python）:
```powershell
python -m http.server 5173
# → http://localhost:5173 へアクセス
```
Service Worker は HTTPS か localhost でのみ有効です。

## デプロイ例
- GitHub Pages: `main` ブランチのルート公開。`sw.js` や `manifest.webmanifest` はルートに配置済み。
- Netlify/Vercel: プロジェクトルートを公開（ビルド不要）。

## ライセンス
プロジェクトに合わせて設定してください。
