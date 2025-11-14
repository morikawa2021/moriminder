//
//  MoriminderApp.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import SwiftUI
import UserNotifications
import CoreData

@main
struct MoriminderApp: App {
    let persistenceController = PersistenceController.shared
    private let notificationActionHandler: NotificationActionHandler
    private let notificationRefreshService: NotificationRefreshService

    @Environment(\.scenePhase) private var scenePhase

    init() {
        // アプリ全体のロケールを日本語に設定
        if let path = Bundle.main.path(forResource: "ja", ofType: "lproj"),
           let _ = Bundle(path: path) {
            UserDefaults.standard.set(["ja"], forKey: "AppleLanguages")
        }

        // TaskManagerとNotificationManagerのインスタンスを作成
        let viewContext = persistenceController.container.viewContext
        let taskManager = TaskManager(viewContext: viewContext)
        let notificationManager = NotificationManager()
        let reminderService = ReminderService(notificationManager: notificationManager)

        // デフォルトプリセット時間の初期化
        PresetTime.createDefaultPresetTimes(in: viewContext)

        // NotificationRefreshServiceを作成
        notificationRefreshService = NotificationRefreshService(
            taskManager: taskManager,
            notificationManager: notificationManager,
            reminderService: reminderService,
            viewContext: viewContext
        )

        // NotificationActionHandlerを作成してデリゲートとして設定
        notificationActionHandler = NotificationActionHandler(
            taskManager: taskManager,
            notificationManager: notificationManager,
            notificationRefreshService: notificationRefreshService
        )
        UNUserNotificationCenter.current().delegate = notificationActionHandler

        // BackgroundTaskManagerを設定
        BackgroundTaskManager.shared.configure(refreshService: notificationRefreshService)
        BackgroundTaskManager.shared.registerBackgroundTasks()

        // 通知カテゴリの登録
        UNNotificationCategory.registerCategories()

        // 通知権限の要求
        _Concurrency.Task {
            try? await notificationManager.requestAuthorization()
        }
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // アプリ起動時に通知をリフレッシュ
                    _Concurrency.Task {
                        try? await notificationRefreshService.refreshNotifications()
                    }
                    // 最初のバックグラウンドタスクをスケジュール
                    BackgroundTaskManager.shared.scheduleNextBackgroundTask()
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // フォアグラウンド復帰時に通知をリフレッシュ
                _Concurrency.Task {
                    try? await notificationRefreshService.refreshNotifications()
                }
            }
        }
    }
}

