# OfflineVault

写真とビデオを端末内へ保存し、インターネットを経由せず近くの Apple 端末へ交換する iOS アプリです。

## プライバシー設計

- メディアは Application Support 内に保存し、`completeFileProtection` を指定。
- サーバー、分析 SDK、広告 SDK、クラウド同期を持たない。
- 端末間交換は `MultipeerConnectivity` の暗号化必須セッションを利用。
- 近距離通信の OS 許可が必要。通信経路は Bluetooth / Wi-Fi Direct 等の Apple が選ぶローカル経路で、アプリからインターネットへアップロードしない。

「絶対に流出しない」は OS、端末、利用者の操作まで含めて保証できないため、重要データでは送信先確認と端末のパスコード設定を併用してください。

## Xcode

1. `OfflineVault.xcodeproj` を Xcode で開く。
2. Signing & Capabilities で Apple Developer Team を選択し、Bundle Identifier を自分のものに変更する。
3. 実機 2 台で起動し、ローカルネットワークとカメラを許可する。
4. 保管庫の「送る」から接続中の端末へ送信する。

## TestFlight CI/CD

GitHub Actions の `testflight.yml` は `main` への push で archive、export、App Store Connect への upload を行います。リポジトリの Actions secrets に次を登録してください。

- `IOS_CERTIFICATE_P12_BASE64`, `IOS_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `APPSTORE_CONNECT_KEY_ID`, `APPSTORE_CONNECT_ISSUER_ID`, `APPSTORE_CONNECT_PRIVATE_KEY_BASE64`
- `IOS_TEAM_ID`, `IOS_BUNDLE_ID`

証明書と provisioning profile は Apple Developer Account で作成し、App Store Connect API Key は TestFlight への upload 権限だけを付与します。CI は Apple の署名資材を使うため、秘密情報は GitHub Actions secrets 以外へ置かないでください。
