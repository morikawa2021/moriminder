//
//  NotificationDebugView.swift
//  Moriminder
//
//  Created on 2025-01-XX.
//

import SwiftUI
import UserNotifications
import CoreData

struct NotificationDebugView: View {
    @State private var notificationDetails: NotificationDetails?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRescheduleConfirm = false
    @State private var isRescheduling = false

    @Environment(\.managedObjectContext) private var viewContext
    private let notificationManager = NotificationManager()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let details = notificationDetails {
                    // 問題の可能性セクション
                    let issues = checkForIssues(details: details)
                    if !issues.isEmpty {
                        Section("⚠️ 問題の可能性") {
                            ForEach(issues, id: \.self) { issue in
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(issue)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    
                    // 統計情報セクション
                    Section("統計情報") {
                        HStack {
                            Text("総通知数")
                            Spacer()
                            Text("\(details.totalCount) / 64")
                                .foregroundColor(details.totalCount >= 64 ? .red : .primary)
                        }
                        
                        HStack {
                            Text("アラーム通知")
                            Spacer()
                            Text("\(details.alarmCount)")
                        }
                        
                        HStack {
                            Text("リマインド通知")
                            Spacer()
                            Text("\(details.reminderCount)")
                        }
                        
                        // 過去の通知の数
                        let pastNotifications = details.allNotifications.filter { notification in
                            if let date = notification.scheduledDate {
                                return date < Date()
                            }
                            return false
                        }
                        if !pastNotifications.isEmpty {
                            HStack {
                                Text("過去の通知")
                                Spacer()
                                Text("\(pastNotifications.count)個")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // 権限状態セクション
                    Section("通知権限（APIから取得した値）") {
                        HStack {
                            Text("認証状態")
                            Spacer()
                            Text(authorizationStatusText(details.authorizationStatus))
                                .foregroundColor(details.authorizationStatus == .authorized || details.authorizationStatus == .provisional ? .green : .red)
                        }
                        
                        // アラートスタイル
                        HStack {
                            Text("アラートスタイル")
                            Spacer()
                            Text(alertStyleText(details.alertStyle))
                                .foregroundColor(details.alertStyle == .none ? .orange : .primary)
                        }
                        
                        // 表示場所の詳細
                        HStack {
                            Text("ロック画面")
                            Spacer()
                            Text(settingText(details.lockScreenSetting))
                                .foregroundColor(details.lockScreenSetting == .disabled ? .orange : .primary)
                        }
                        
                        HStack {
                            Text("通知センター")
                            Spacer()
                            Text(settingText(details.notificationCenterSetting))
                                .foregroundColor(details.notificationCenterSetting == .enabled ? .green : .orange)
                        }
                        
                        // バナーの設定はalertStyleで判断
                        HStack {
                            Text("バナー")
                            Spacer()
                            Text(details.alertStyle == .banner ? "有効" : "無効")
                                .foregroundColor(details.alertStyle == .banner ? .green : .orange)
                        }
                        
                        HStack {
                            Text("サウンド")
                            Spacer()
                            Text(settingText(details.soundSetting))
                                .foregroundColor(details.soundSetting == .disabled ? .orange : .primary)
                        }
                        
                        HStack {
                            Text("バッジ")
                            Spacer()
                            Text(settingText(details.badgeSetting))
                                .foregroundColor(details.badgeSetting == .disabled ? .orange : .primary)
                        }
                        
                        // 重要な注釈
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⚠️ 重要な注意")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("これらの値は、iOSの`UNNotificationSettings` APIから取得したものです。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("システム設定でユーザーが個別に変更した設定（サウンド、バッジなど）は、このAPIでは正確に反映されない場合があります。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("実際の設定は「設定」アプリ > 「通知」> 「Moriminder」で確認してください。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // アラーム予定セクション
                    if !details.alarmDates.isEmpty {
                        Section("アラーム予定 (\(details.alarmDates.count)個)") {
                            ForEach(Array(details.alarmDates.enumerated()), id: \.offset) { index, date in
                                HStack {
                                    Text("\(index + 1).")
                                    Spacer()
                                    Text(dateFormatter.string(from: date))
                                        .font(.system(.body, design: .monospaced))
                                    if date < Date() {
                                        Text("(過去)")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    
                    // リマインド予定セクション
                    if !details.reminderDates.isEmpty {
                        Section("リマインド予定 (\(details.reminderDates.count)個)") {
                            ForEach(Array(details.reminderDates.enumerated()), id: \.offset) { index, date in
                                HStack {
                                    Text("\(index + 1).")
                                    Spacer()
                                    Text(dateFormatter.string(from: date))
                                        .font(.system(.body, design: .monospaced))
                                    if date < Date() {
                                        Text("(過去)")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    
                    // 全通知詳細セクション
                    Section("全通知詳細") {
                        ForEach(Array(details.allNotifications.enumerated()), id: \.offset) { index, notification in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(notification.identifier)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                
                                Text(notification.title)
                                    .font(.headline)
                                
                                Text(notification.body)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let date = notification.scheduledDate {
                                    HStack {
                                        Text("予定時刻:")
                                        Text(dateFormatter.string(from: date))
                                            .font(.system(.caption, design: .monospaced))
                                        if date < Date() {
                                            Text("(過去)")
                                                .foregroundColor(.red)
                                                .font(.caption)
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("カテゴリ: \(notification.categoryIdentifier)")
                                    Spacer()
                                    Text("重要度: \(interruptionLevelText(notification.interruptionLevel))")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } else if let error = errorMessage {
                    Section {
                        Text("エラー: \(error)")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("通知デバッグ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showRescheduleConfirm = true
                    }) {
                        if isRescheduling {
                            ProgressView()
                        } else {
                            Label("再スケジュール", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(isRescheduling)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("更新") {
                        loadNotificationDetails()
                    }
                }
            }
            .alert("通知を再スケジュール", isPresented: $showRescheduleConfirm) {
                Button("キャンセル", role: .cancel) {}
                Button("実行", role: .destructive) {
                    rescheduleAllNotifications()
                }
            } message: {
                Text("すべての通知を削除して、新しいコードで再スケジュールします。この操作により、修正が反映されます。")
            }
            .onAppear {
                loadNotificationDetails()
            }
        }
    }
    
    private func loadNotificationDetails() {
        isLoading = true
        errorMessage = nil

        _Concurrency.Task {
            let details = await notificationManager.getNotificationDetails()
            await MainActor.run {
                self.notificationDetails = details
                self.isLoading = false
            }
        }
    }

    private func rescheduleAllNotifications() {
        isRescheduling = true

        _Concurrency.Task {
            do {
                // 1. すべてのタスクを取得
                let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "isCompleted == NO AND isArchived == NO")

                let tasks = try await viewContext.perform {
                    try self.viewContext.fetch(fetchRequest)
                }

                print("🔄 \(tasks.count)個のタスクの通知を再スケジュール中...")

                // 2. 各タスクの通知を削除して再スケジュール
                for task in tasks {
                    // 既存の通知を削除
                    await notificationManager.cancelNotifications(for: task)

                    // アラームを再スケジュール
                    if task.alarmEnabled {
                        try? await notificationManager.scheduleAlarm(for: task)
                    }

                    // リマインダーを再スケジュール
                    if task.reminderEnabled {
                        let reminderService = ReminderService(notificationManager: notificationManager)
                        try? await reminderService.scheduleReminder(for: task)
                    }
                }

                print("✅ 通知の再スケジュール完了")

                // 3. 通知詳細を再読み込み
                await MainActor.run {
                    self.isRescheduling = false
                    self.loadNotificationDetails()
                }
            } catch {
                print("❌ 通知の再スケジュールエラー: \(error)")
                await MainActor.run {
                    self.isRescheduling = false
                    self.errorMessage = "再スケジュールエラー: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func authorizationStatusText(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "未決定"
        case .denied:
            return "拒否"
        case .authorized:
            return "許可"
        case .provisional:
            return "暫定許可"
        case .ephemeral:
            return "一時的"
        @unknown default:
            return "不明"
        }
    }
    
    private func settingText(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .notSupported:
            return "未サポート"
        case .disabled:
            return "無効"
        case .enabled:
            return "有効"
        @unknown default:
            return "不明"
        }
    }
    
    private func alertStyleText(_ style: UNAlertStyle) -> String {
        switch style {
        case .none:
            return "なし"
        case .banner:
            return "バナー"
        case .alert:
            return "アラート"
        @unknown default:
            return "不明"
        }
    }
    
    private func interruptionLevelText(_ level: UNNotificationInterruptionLevel) -> String {
        switch level {
        case .passive:
            return "低"
        case .active:
            return "通常"
        case .timeSensitive:
            return "時間敏感"
        case .critical:
            return "重要"
        @unknown default:
            return "不明"
        }
    }
    
    // 問題の可能性をチェック
    private func checkForIssues(details: NotificationDetails) -> [String] {
        var issues: [String] = []
        
        // 1. 通知権限の問題
        if details.authorizationStatus != .authorized && details.authorizationStatus != .provisional {
            issues.append("通知権限が許可されていません（\(authorizationStatusText(details.authorizationStatus))）")
        }
        
        // 2. 通知の制限に達している
        if details.totalCount >= 64 {
            issues.append("通知の制限（64個）に達しています。一部の通知がスケジュールされていない可能性があります。")
        }
        
        // 3. 過去の通知がある
        let pastNotifications = details.allNotifications.filter { notification in
            if let date = notification.scheduledDate {
                return date < Date()
            }
            return false
        }
        if !pastNotifications.isEmpty {
            issues.append("過去の時刻の通知が\(pastNotifications.count)個あります。これらは配信されません。")
        }
        
        // 4. アラート設定が無効（ただし、通知センターのみが有効な場合もある）
        if details.alertSetting != .enabled {
            if details.notificationCenterSetting == .enabled {
                issues.append("アラート設定が無効ですが、通知センターは有効です。通知は通知センターにのみ表示されます（ロック画面やバナーでは表示されません）。")
            } else {
                issues.append("アラート設定が無効になっています。通知が表示されない可能性があります。")
            }
        } else if details.lockScreenSetting == .disabled && details.alertStyle != .banner {
            issues.append("ロック画面とバナーが無効になっています。通知センターでのみ通知が表示されます。")
        }
        
        // 6. APIの値とシステム設定が一致しない可能性があることを警告（この警告は削除 - 実際には一致していることが確認されたため）
        
        // 5. 通知が少なすぎる（タスクがあるのに通知がない可能性）
        if details.totalCount == 0 {
            issues.append("スケジュールされている通知がありません。タスクに通知設定があるか確認してください。")
        }
        
        return issues
    }
}

