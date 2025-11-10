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
        
        // デフォルトプリセット時間の初期化
        PresetTime.createDefaultPresetTimes(in: viewContext)
        
        // NotificationActionHandlerを作成してデリゲートとして設定
        notificationActionHandler = NotificationActionHandler(
            taskManager: taskManager,
            notificationManager: notificationManager
        )
        UNUserNotificationCenter.current().delegate = notificationActionHandler
        
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
        }
    }
}

