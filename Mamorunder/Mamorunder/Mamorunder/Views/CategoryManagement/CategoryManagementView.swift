//
//  CategoryManagementView.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import SwiftUI
import CoreData

struct CategoryManagementView: View {
    @StateObject private var viewModel: CategoryManagementViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    init(viewContext: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: CategoryManagementViewModel(viewContext: viewContext))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                AppHeaderView(screenTitle: "カテゴリ管理")
                
                // カテゴリリスト
                if viewModel.categories.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("カテゴリがありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("タスク登録時にカテゴリを作成できます")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.categories, id: \.objectID) { category in
                            CategoryManagementRow(
                                category: category,
                                viewModel: viewModel
                            )
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadCategories()
            }
            .alert("カテゴリを削除しますか？", isPresented: Binding(
                get: { viewModel.categoryToDelete != nil },
                set: { if !$0 { viewModel.categoryToDelete = nil } }
            )) {
                Button("キャンセル", role: .cancel) {
                    viewModel.categoryToDelete = nil
                }
                Button("削除", role: .destructive) {
                    if let category = viewModel.categoryToDelete {
                        viewModel.deleteCategory(category)
                    }
                }
            } message: {
                if let category = viewModel.categoryToDelete {
                    let taskCount = viewModel.getTaskCount(for: category)
                    if taskCount > 0 {
                        Text("「\(category.name ?? "")」を削除しますか？\nこのカテゴリを使用しているタスクが\(taskCount)件あります。")
                    } else {
                        Text("「\(category.name ?? "")」を削除しますか？")
                    }
                }
            }
            .sheet(item: Binding(
                get: { viewModel.categoryToEdit },
                set: { if $0 == nil { viewModel.cancelEditing() } }
            )) { category in
                CategoryEditView(
                    category: category,
                    name: $viewModel.editingName,
                    color: $viewModel.editingColor,
                    showingColorPicker: $viewModel.showingColorPicker,
                    onSave: {
                        viewModel.saveEditing()
                    },
                    onCancel: {
                        viewModel.cancelEditing()
                    }
                )
            }
        }
    }
}

struct CategoryManagementRow: View {
    let category: Category
    @ObservedObject var viewModel: CategoryManagementViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // カテゴリの色表示
            if let colorHex = category.color {
                Circle()
                    .fill(CategoryManager.colorFromHex(colorHex))
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name ?? "")
                    .font(.body)
                    .foregroundColor(.primary)
                
                // 使用回数とタスク数を表示
                HStack(spacing: 8) {
                    if category.usageCount > 0 {
                        Label("\(category.usageCount)回使用", systemImage: "number.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    let taskCount = viewModel.getTaskCount(for: category)
                    if taskCount > 0 {
                        Label("\(taskCount)件のタスク", systemImage: "list.bullet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 編集ボタン
            Button {
                viewModel.startEditing(category)
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.categoryToDelete = category
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

struct CategoryEditView: View {
    let category: Category
    @Binding var name: String
    @Binding var color: String
    @Binding var showingColorPicker: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("カテゴリ名") {
                    TextField("カテゴリ名", text: $name)
                }
                
                Section("色") {
                    HStack {
                        Circle()
                            .fill(CategoryManager.colorFromHex(color))
                            .frame(width: 30, height: 30)
                        
                        Text("色を選択")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button {
                            showingColorPicker = true
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 色のプリセット
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            ForEach(0..<4, id: \.self) { index in
                                if index < CategoryManager.defaultColors.count {
                                    ColorSelectionButton(
                                        colorHex: CategoryManager.defaultColors[index],
                                        isSelected: color == CategoryManager.defaultColors[index],
                                        onTap: { color = CategoryManager.defaultColors[index] }
                                    )
                                }
                            }
                        }
                        HStack(spacing: 16) {
                            ForEach(4..<8, id: \.self) { index in
                                if index < CategoryManager.defaultColors.count {
                                    ColorSelectionButton(
                                        colorHex: CategoryManager.defaultColors[index],
                                        isSelected: color == CategoryManager.defaultColors[index],
                                        onTap: { color = CategoryManager.defaultColors[index] }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("カテゴリを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct ColorSelectionButton: View {
    let colorHex: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Circle()
                .fill(CategoryManager.colorFromHex(colorHex))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// プレビュー
#Preview {
    CategoryManagementView(viewContext: PersistenceController.preview.container.viewContext)
}

