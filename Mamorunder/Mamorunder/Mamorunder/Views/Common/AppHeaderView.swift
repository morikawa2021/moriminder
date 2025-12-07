//
//  AppHeaderView.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import SwiftUI

struct AppHeaderView: View {
    let screenTitle: String
    
    // アプリバージョン情報を取得
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 画面名
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text(screenTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            )
            
            // セパレーター
            Divider()
        }
    }
}

// ナビゲーションバー用のアプリ名とバージョン表示
struct AppTitleToolbar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
                Text("守るんだぁ")
                    .font(.headline)
                Text(appVersion)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
}

