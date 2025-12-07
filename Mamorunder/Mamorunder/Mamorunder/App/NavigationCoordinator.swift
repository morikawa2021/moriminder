//
//  NavigationCoordinator.swift
//  Mamorunder
//
//  Created on 2025-11-25.
//

import Foundation
import SwiftUI
import Combine

/// アプリ全体のナビゲーション状態を管理
/// コールド起動時の通知タップでも確実にナビゲーションを実行する
class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()

    // MARK: - Navigation State
    @Published var taskDetailToShow: UUID?
    @Published var taskToComplete: UUID?
    @Published var taskToStopReminder: UUID?

    // MARK: - UI Ready State
    @Published private(set) var isUIReady: Bool = false

    // MARK: - Pending Navigation (コールドスタート用)
    private var pendingNavigation: PendingNavigation?

    enum PendingNavigation {
        case showTaskDetail(UUID)
        case completeTask(UUID)
        case stopReminder(UUID)
    }

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        // タスク詳細表示リクエスト
        NotificationCenter.default.publisher(for: NSNotification.Name("TaskDetailRequested"))
            .compactMap { $0.userInfo?["taskId"] as? UUID }
            .sink { [weak self] taskId in
                self?.handleTaskDetailRequest(taskId: taskId)
            }
            .store(in: &cancellables)

        // 完了リクエスト
        NotificationCenter.default.publisher(for: NSNotification.Name("TaskCompleteRequested"))
            .compactMap { $0.userInfo?["taskId"] as? UUID }
            .sink { [weak self] taskId in
                self?.handleCompleteRequest(taskId: taskId)
            }
            .store(in: &cancellables)

        // リマインド停止リクエスト
        NotificationCenter.default.publisher(for: NSNotification.Name("TaskReminderStopRequested"))
            .compactMap { $0.userInfo?["taskId"] as? UUID }
            .sink { [weak self] taskId in
                self?.handleStopReminderRequest(taskId: taskId)
            }
            .store(in: &cancellables)
    }

    // MARK: - Navigation Handling

    private func handleTaskDetailRequest(taskId: UUID) {
        if isUIReady {
            taskDetailToShow = taskId
        } else {
            pendingNavigation = .showTaskDetail(taskId)
        }
    }

    private func handleCompleteRequest(taskId: UUID) {
        if isUIReady {
            taskToComplete = taskId
        } else {
            pendingNavigation = .completeTask(taskId)
        }
    }

    private func handleStopReminderRequest(taskId: UUID) {
        if isUIReady {
            taskToStopReminder = taskId
        } else {
            pendingNavigation = .stopReminder(taskId)
        }
    }

    // MARK: - UI Ready

    func markUIReady() {
        guard !isUIReady else { return }
        isUIReady = true

        // 保留中のナビゲーションを実行（NavigationCoordinator内部の保留状態）
        if let pending = pendingNavigation {
            DispatchQueue.main.async { [weak self] in
                switch pending {
                case .showTaskDetail(let taskId):
                    self?.taskDetailToShow = taskId
                case .completeTask(let taskId):
                    self?.taskToComplete = taskId
                case .stopReminder(let taskId):
                    self?.taskToStopReminder = taskId
                }
            }
            pendingNavigation = nil
            return
        }

        // NotificationActionHandlerのstatic変数に保存された保留状態をチェック
        // （コールド起動時、NavigationCoordinatorの初期化前に通知がタップされた場合）
        DispatchQueue.main.async { [weak self] in
            if let taskId = NotificationActionHandler.pendingTaskDetailId {
                NotificationActionHandler.pendingTaskDetailId = nil
                self?.taskDetailToShow = taskId
            }
            if let taskId = NotificationActionHandler.pendingTaskCompleteId {
                NotificationActionHandler.pendingTaskCompleteId = nil
                self?.taskToComplete = taskId
            }
            if let taskId = NotificationActionHandler.pendingTaskStopReminderId {
                NotificationActionHandler.pendingTaskStopReminderId = nil
                self?.taskToStopReminder = taskId
            }
        }
    }

    // MARK: - Clear State

    func clearTaskDetail() {
        taskDetailToShow = nil
    }

    func clearTaskToComplete() {
        taskToComplete = nil
    }

    func clearTaskToStopReminder() {
        taskToStopReminder = nil
    }
}
