# OfflineVault 引き継ぎメモ

作成日: 2026-09-24
プロジェクト: `/Users/yoshida-rio/projects/OfflineVault`

## 目的

インターネット経由で写真やビデオを送信せず、iPhone 内に保存し、近くの Apple 端末とローカル通信でファイル交換する iOS アプリ。

## 今までに実装したこと

- SwiftUI ベースの iOS アプリを作成。
- Xcode プロジェクトを作成: `OfflineVault.xcodeproj`
- 写真撮影を実装。
- ビデオ録画を実装。
- メディアを Application Support 配下へ保存。
- 保存時に `completeFileProtection` を指定。
- メディア一覧、削除、撮影日時表示を実装。
- `MultipeerConnectivity` を使った端末間通信を実装。
- `MCSession` は `encryptionPreference: .required` を指定。
- 近くの端末を自動検出し、接続後にファイル送信できるようにした。
- 受信したファイルを端末内ライブラリへ保存する処理を実装。
- カメラとローカルネットワークの用途説明を `Info.plist` に追加。
- GitHub Actions の TestFlight デプロイ workflow を作成。
- TestFlight 用の署名情報と Secrets の説明を `README.md` に追加。
- `.gitignore` を作成し、証明書・Provisioning Profile・API key を除外。

## 主なファイル

- `OfflineVaultApp.swift`: アプリのエントリーポイント
- `ContentView.swift`: 撮影画面、保管庫画面、送受信 UI
- `CameraViewModel.swift`: AVFoundation による写真・ビデオ撮影
- `CameraPreview.swift`: カメラプレビュー
- `MediaItem.swift`: メディアモデルとローカル保存処理
- `PeerTransferService.swift`: MultipeerConnectivity による端末間転送
- `Info.plist`: カメラ・ローカルネットワーク権限
- `.github/workflows/testflight.yml`: TestFlight 自動配布
- `README.md`: セットアップとプライバシー設計

## 検証済み

以下は 2026-09-24 時点で成功済み。

```sh
xcodebuild -project /Users/yoshida-rio/projects/OfflineVault/OfflineVault.xcodeproj \
  -scheme OfflineVault \
  -sdk iphonesimulator \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO build
```

結果: `BUILD SUCCEEDED`

```sh
plutil -lint /Users/yoshida-rio/projects/OfflineVault/Info.plist
```

結果: `Info.plist: OK`

```sh
xcodebuild -project /Users/yoshida-rio/projects/OfflineVault/OfflineVault.xcodeproj -list
```

結果: `OfflineVault` scheme を確認済み。

## 次にやること

### 優先度高

1. Xcode で実機 2 台にインストールして動作確認する。
   - カメラ権限を許可。
   - ローカルネットワーク権限を許可。
   - 写真撮影、ビデオ録画、一覧表示、削除を確認。
   - 端末 A から端末 B へ送信。
   - 端末 B で受信ファイルが保管庫に表示されることを確認。
2. Apple Developer の Team と Bundle Identifier を設定する。
   - 現在の仮 Bundle ID は `com.example.OfflineVault`。
3. 実際の署名設定を確認する。
   - Apple Distribution 証明書。
   - App Store 用 Provisioning Profile。
   - App Store Connect API Key。
4. GitHub Actions Secrets を登録して workflow を手動実行する。
5. TestFlight の内部テスターで配布を確認する。

### 優先度中

- 受信完了時に一時ファイルを削除する。
- 送信前に接続先端末名を表示し、ユーザーが送信先を確認できるようにする。
- 複数端末が見つかった場合に自動接続せず、接続先を選べる UI にする。
- 転送中の進捗率を表示する。
- 受信した動画・写真を実際のサムネイルで表示する。
- 写真撮影時のカメラ切り替え、フラッシュ、動画録画時間表示を追加する。
- `OfflineVaultTests.swift` を Xcode の Test Target に追加するか、不要なら削除する。
- アプリ起動時にパスコード／生体認証ロックを追加する。

### 優先度低

- App Store 用のアイコンと Launch Screen を追加する。
- アプリ名、Bundle ID、バージョン番号を正式なものへ変更する。
- Privacy Manifest と App Store Connect のプライバシー申告を確認する。
- 実機でバックグラウンド復帰、低容量、転送中の中断を確認する。
- GitHub Actions に simulator build と lint の Pull Request 用 workflow を追加する。

## 注意点

- 「絶対に流出しない」は OS、端末、利用者の操作まで含めて保証できない。README にもその旨を記載済み。
- アプリから外部サーバーへアップロードする処理は追加していない。
- `MultipeerConnectivity` の通信経路は Apple が Bluetooth / Wi-Fi Direct 等から選ぶ。アプリ側ではインターネット API を使わない設計。
- TestFlight への実アップロードは、Apple の証明書・Provisioning Profile・App Store Connect API Key が未設定のため未実行。
- Fastlane は使用していない。GitHub Actions 内の `xcodebuild` と `xcrun altool` を使用する構成。

## TestFlight Secrets

README と `.github/workflows/testflight.yml` で以下を使用する。

- `IOS_CERTIFICATE_P12_BASE64`
- `IOS_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `APPSTORE_CONNECT_KEY_ID`
- `APPSTORE_CONNECT_ISSUER_ID`
- `APPSTORE_CONNECT_PRIVATE_KEY_BASE64`
- `IOS_TEAM_ID`
- `IOS_BUNDLE_ID`

## 再開時の最初の確認コマンド

```sh
cd /Users/yoshida-rio/projects/OfflineVault
xcodebuild -project OfflineVault.xcodeproj -scheme OfflineVault -list
xcodebuild -project OfflineVault.xcodeproj -scheme OfflineVault -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

その後、Xcode で `OfflineVault.xcodeproj` を開き、実機ビルドに進む。
