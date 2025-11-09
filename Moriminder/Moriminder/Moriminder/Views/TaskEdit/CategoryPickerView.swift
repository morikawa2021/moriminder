//
//  CategoryPickerView.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import SwiftUI
import CoreData

struct CategoryPickerView: View {
    @Binding var selectedCategory: Category?
    let categories: [Category]
    var onCategoryCreated: (() -> Void)? = nil
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var searchText: String = ""
    @State private var showColorPicker = false
    
    private var filteredCategories: [Category] {
        var result: [Category] = []
        
        if searchText.isEmpty {
            result = categories
        } else {
            result = categories.filter { category in
                category.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        // 選択されたカテゴリがリストに含まれていない場合は追加
        if let selected = selectedCategory,
           !result.contains(where: { $0.objectID == selected.objectID }) {
            result.insert(selected, at: 0)
        }
        
        return result
    }
    
    private var categoryManager: CategoryManager {
        CategoryManager(viewContext: viewContext)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 検索フィールド
            TextField("カテゴリ名を入力", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            
            // カテゴリリスト
            if !filteredCategories.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(filteredCategories, id: \.objectID) { category in
                            CategoryRow(
                                category: category,
                                isSelected: selectedCategory?.objectID == category.objectID
                            ) {
                                selectedCategory = category
                                searchText = ""
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
            
            // 新規カテゴリ作成
            if !searchText.isEmpty && !filteredCategories.contains(where: { $0.name?.localizedCaseInsensitiveCompare(searchText) == .orderedSame }) {
                Button {
                    let newCategory = categoryManager.findOrCreateCategory(name: searchText)
                    selectedCategory = newCategory
                    do {
                        try viewContext.save()
                        // カテゴリ作成後に親のViewModelに通知
                        onCategoryCreated?()
                        // カテゴリ変更通知を送信
                        NotificationCenter.default.post(name: NSNotification.Name("CategoriesDidChange"), object: nil)
                        // 保存後に検索テキストをクリア
                        searchText = ""
                    } catch {
                        print("カテゴリ保存エラー: \(error)")
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("「\(searchText)」を新規作成")
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // 選択解除
            if selectedCategory != nil {
                Button {
                    selectedCategory = nil
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("選択解除")
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

struct CategoryRow: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // カテゴリの色表示
                if let colorHex = category.color {
                    Circle()
                        .fill(CategoryManager.colorFromHex(colorHex))
                        .frame(width: 20, height: 20)
                }
                
                Text(category.name ?? "")
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

