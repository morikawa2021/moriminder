//
//  SplashView.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import SwiftUI
import CoreData

struct SplashView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator

    var body: some View {
        if isActive {
            TaskListView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(navigationCoordinator)
        } else {
            ZStack {
                // 背景色（アプリのテーマカラーに合わせる）
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // アプリアイコンまたはロゴ
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .symbolEffect(.bounce, value: opacity)
                    
                    // アプリ名
                    Text("マモルンダー")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // サブタイトル
                    Text("タスクを忘れない")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .opacity(opacity)
            }
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) {
                    opacity = 1.0
                }
                
                // 2秒後にメイン画面に遷移
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isActive = true
                        navigationCoordinator.markUIReady()
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(NavigationCoordinator.shared)
}

