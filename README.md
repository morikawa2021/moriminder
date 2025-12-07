# Mamorunder（マモルンダー）

リマインド通知を何度もスヌーズしてしまい、結局タスクを実行せずに忘れてしまう人のために、通知を無視しにくく、タスクを確実に実行できるようにサポートするタスク管理アプリ。

## プロジェクト構成

```
Mamorunder/
├── App/
│   ├── MamorunderApp.swift          # アプリエントリーポイント
│   └── PersistenceController.swift  # Core Dataスタック
├── Models/
│   ├── Enums/                       # 列挙型定義
│   └── Errors/                      # エラー定義
├── Views/
│   ├── TaskList/                    # タスク一覧画面
│   └── TaskEdit/                    # タスク登録・編集画面
├── ViewModels/                      # ViewModel
├── Services/                        # ビジネスロジック層
└── Resources/
    └── CoreData/                    # Core Dataモデルファイル
```

## セットアップ手順

### 1. Xcodeプロジェクトの作成

1. Xcodeを開く
2. "Create a new Xcode project"を選択
3. "iOS" > "App"を選択
4. プロジェクト情報を入力:
   - Product Name: `Mamorunder`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Use Core Data: ✅ **チェックを入れる**
   - Include Tests: ✅ オプション

### 2. 既存ファイルの追加

作成したXcodeプロジェクトに、このリポジトリの`Mamorunder/`ディレクトリ内のファイルを追加します。

1. Xcodeでプロジェクトを開く
2. プロジェクトナビゲーターで右クリック > "Add Files to..."
3. `Mamorunder/`ディレクトリを選択
4. "Create groups"を選択
5. "Add"をクリック

### 3. Core Dataモデルの作成

1. Xcodeで`Mamorunder.xcdatamodeld`ファイルを開く（または新規作成）
2. 以下のエンティティを作成:

#### Task エンティティ
- `id`: UUID (Optional)
- `title`: String
- `createdAt`: Date
- `completedAt`: Date (Optional)
- `category`: Category (Relationship, Optional, To-One)
- `priority`: String (Optional)
- `taskType`: String (Optional)
- `deadline`: Date (Optional)
- `startDateTime`: Date (Optional)
- `alarmDateTime`: Date (Optional)
- `alarmSound`: String (Optional)
- `alarmEnabled`: Boolean
- `reminderEnabled`: Boolean
- `reminderInterval`: Integer 32
- `reminderStartTime`: Date (Optional)
- `reminderEndTime`: Date (Optional)
- `snoozeMaxCount`: Integer 32
- `snoozeUnlimited`: Boolean
- `snoozeCount`: Integer 32
- `lastSnoozeDateTime`: Date (Optional)
- `isRepeating`: Boolean
- `repeatPattern`: Transformable (Optional, Custom Class: `RepeatPattern`)
- `repeatEndDate`: Date (Optional)
- `parentTaskId`: UUID (Optional)
- `isCompleted`: Boolean
- `isArchived`: Boolean

#### Category エンティティ
- `id`: UUID
- `name`: String
- `color`: String
- `createdAt`: Date
- `usageCount`: Integer 32
- `tasks`: Task (Relationship, To-Many)

#### NotificationRecord エンティティ
- `id`: UUID
- `taskId`: UUID
- `notificationId`: String
- `scheduledTime`: Date
- `notificationType`: String
- `isDelivered`: Boolean
- `deliveredAt`: Date (Optional)
- `task`: Task (Relationship, To-One)

#### PresetTime エンティティ
- `id`: UUID
- `name`: String
- `hour`: Integer 32
- `minute`: Integer 32
- `offsetDays`: Integer 32
- `isDefault`: Boolean
- `order`: Integer 32

### 4. Info.plistの設定

通知権限の説明を追加:

```xml
<key>NSUserNotificationsUsageDescription</key>
<string>重要なタスクの通知を時間に敏感な通知として送信します</string>
```

### 5. ビルドと実行

1. シミュレーターまたは実機を選択
2. ⌘+R でビルド&実行

## 開発状況

### Phase 1: 基本機能（完了）
- [x] プロジェクト構造の作成
- [x] 列挙型定義
- [x] エラー定義
- [x] TaskManager実装
- [x] NotificationManager実装
- [x] ReminderService実装
- [x] 基本UI実装
- [x] Core Dataモデルの作成（Xcodeで手動作成が必要）
- [x] Core Dataエンティティの拡張
- [x] 通知カテゴリの登録
- [x] 通知アクションハンドラの実装
- [x] TaskEditViewModelのsave()メソッド実装
- [x] TaskEditViewModelのloadCategories()とloadPresetTimes()実装
- [x] TaskEditViewModelのrepeatPattern読み込み実装
- [x] TaskListViewModelの確認ダイアログ実装
- [x] TaskListViewのフィルタ・ソート機能接続
- [x] TaskManagerのfetchTask(id:)メソッド実装
- [x] NotificationActionHandlerの通知アクション処理実装

### Phase 2: 高度な機能（完了）
- [x] カテゴリ機能
  - [x] CategoryManagerサービスの実装
  - [x] CategoryPickerViewの実装（オートコンプリート対応、カテゴリ新規作成）
  - [x] TaskCardViewでのカテゴリ色分け表示
- [x] 重要度機能
  - [x] ReminderSettingViewでの重要度に応じたデフォルト設定の自動適用
- [x] 繰り返しタスク機能
  - [x] RepeatSettingViewの実装
  - [x] RepeatingTaskGeneratorサービスの実装
  - [x] TaskManagerの繰り返しタスク生成処理の実装
- [x] 自然言語解析機能
  - [x] NaturalLanguageParserサービスの実装
  - [x] TaskEditViewへの自然言語解析統合
  - [x] DateSettingViewのプリセット時間表示実装

### Phase 3: 拡張機能（進行中）
- [ ] タスク細分化機能
  - [x] TaskSubdivisionServiceの基本実装
  - [x] TaskSubdivisionViewのUI実装
  - [x] TaskSubdivisionViewModelの基本実装
  - [ ] LLM API連携（未実装）
- [x] プリセット時間機能
  - [x] PresetTimeButtonの実装
  - [x] DateSettingViewでのプリセット時間表示
  - [x] デフォルトプリセット時間の初期化処理
- [x] 通知アクション機能
  - [x] NotificationActionHandlerの実装
  - [x] TaskListViewでの通知アクションイベント処理
  - [x] 完了・停止確認ダイアログの実装
  - [x] タスク詳細表示の実装

## 注意事項

- Core Dataモデルファイル（`.xcdatamodeld`）はXcodeで手動作成する必要があります
- 通知権限は初回起動時に要求されます
- iOS 15.0以上が必要です

## 参考資料

- [要求仕様書](docs/要求仕様書.md)
- [詳細仕様書](docs/詳細仕様書.md)

