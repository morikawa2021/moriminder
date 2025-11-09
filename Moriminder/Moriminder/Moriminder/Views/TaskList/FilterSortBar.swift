//
//  FilterSortBar.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import SwiftUI

enum FilterMode: Equatable {
    case all
    case incomplete
    case completed
    case category(String)
    case priority(Priority)
    
    var displayName: String {
        switch self {
        case .all:
            return "すべて"
        case .incomplete:
            return "未完了"
        case .completed:
            return "完了済み"
        case .category(let categoryName):
            return "カテゴリ: \(categoryName)"
        case .priority(let priority):
            let priorityName: String
            switch priority {
            case .low:
                priorityName = "低"
            case .medium:
                priorityName = "中"
            case .high:
                priorityName = "高"
            }
            return "重要度: \(priorityName)"
        }
    }
}

enum SortMode: Equatable {
    case createdAtDesc
    case createdAtAsc
    case priorityDesc  // 重要度（高い順）
    case priorityAsc   // 重要度（低い順）
    case deadlineAsc   // 期限（早い順）
    case deadlineDesc  // 期限（遅い順）
    case startDateTimeAsc   // 開始日時（早い順）
    case startDateTimeDesc  // 開始日時（遅い順）
    case alarmDateTime
    case category
    case alphabetical
    
    var displayName: String {
        switch self {
        case .createdAtDesc:
            return "登録日時（新しい順）"
        case .createdAtAsc:
            return "登録日時（古い順）"
        case .priorityDesc:
            return "重要度（高い順）"
        case .priorityAsc:
            return "重要度（低い順）"
        case .deadlineAsc:
            return "期限（早い順）"
        case .deadlineDesc:
            return "期限（遅い順）"
        case .startDateTimeAsc:
            return "開始日時（早い順）"
        case .startDateTimeDesc:
            return "開始日時（遅い順）"
        case .alarmDateTime:
            return "アラーム日時"
        case .category:
            return "カテゴリ"
        case .alphabetical:
            return "アルファベット順"
        }
    }
}

struct FilterSortBar: View {
    @Binding var filterMode: FilterMode
    @Binding var sortMode: SortMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var categories: [Category] = []
    
    var body: some View {
        HStack(spacing: 12) {
            // フィルタボタン
            Menu {
                Button {
                    filterMode = .all
                } label: {
                    HStack {
                        Text("すべて")
                        Spacer()
                        if filterMode == .all {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button {
                    filterMode = .incomplete
                } label: {
                    HStack {
                        Text("未完了")
                        Spacer()
                        if filterMode == .incomplete {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button {
                    filterMode = .completed
                } label: {
                    HStack {
                        Text("完了済み")
                        Spacer()
                        if filterMode == .completed {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                if !categories.isEmpty {
                    Divider()
                    
                    ForEach(categories, id: \.id) { category in
                        Button {
                            filterMode = .category(category.name ?? "")
                        } label: {
                            HStack {
                                if let colorHex = category.color {
                                    Circle()
                                        .fill(CategoryManager.colorFromHex(colorHex))
                                        .frame(width: 12, height: 12)
                                }
                                Text(category.name ?? "")
                                Spacer()
                                if case .category(let categoryName) = filterMode, categoryName == category.name {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("ﾌｨﾙﾀ: \(filterMode.displayName)")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .buttonStyle(.plain)
            .onAppear {
                loadCategories()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CategoriesDidChange"))) { _ in
                loadCategories()
            }
            
            Spacer(minLength: 8)
            
            // ソートボタン
            Menu {
                Menu("期限") {
                    Button {
                        sortMode = .deadlineAsc
                    } label: {
                        HStack {
                            Text("早い順")
                            Spacer()
                            if sortMode == .deadlineAsc {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button {
                        sortMode = .deadlineDesc
                    } label: {
                        HStack {
                            Text("遅い順")
                            Spacer()
                            if sortMode == .deadlineDesc {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Menu("重要度") {
                    Button {
                        sortMode = .priorityDesc
                    } label: {
                        HStack {
                            Text("高い順")
                            Spacer()
                            if sortMode == .priorityDesc {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button {
                        sortMode = .priorityAsc
                    } label: {
                        HStack {
                            Text("低い順")
                            Spacer()
                            if sortMode == .priorityAsc {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Menu("開始日時") {
                    Button {
                        sortMode = .startDateTimeAsc
                    } label: {
                        HStack {
                            Text("早い順")
                            Spacer()
                            if sortMode == .startDateTimeAsc {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button {
                        sortMode = .startDateTimeDesc
                    } label: {
                        HStack {
                            Text("遅い順")
                            Spacer()
                            if sortMode == .startDateTimeDesc {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Menu("登録日時") {
                    Button {
                        sortMode = .createdAtDesc
                    } label: {
                        HStack {
                            Text("新しい順")
                            Spacer()
                            if sortMode == .createdAtDesc {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button {
                        sortMode = .createdAtAsc
                    } label: {
                        HStack {
                            Text("古い順")
                            Spacer()
                            if sortMode == .createdAtAsc {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text("ｿｰﾄ: \(sortMode.displayName)")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func loadCategories() {
        let categoryManager = CategoryManager(viewContext: viewContext)
        categories = categoryManager.fetchCategories()
    }
}

