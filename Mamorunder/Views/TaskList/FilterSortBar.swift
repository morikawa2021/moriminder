//
//  FilterSortBar.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import SwiftUI

enum FilterMode {
    case all
    case incomplete
    case completed
    case category(String)
    case priority(Priority)
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
    
    var body: some View {
        HStack {
            // フィルタボタン
            Menu {
                Button("すべて") {
                    filterMode = .all
                }
                Button("未完了") {
                    filterMode = .incomplete
                }
                Button("完了済み") {
                    filterMode = .completed
                }
            } label: {
                Label("フィルタ", systemImage: "line.3.horizontal.decrease.circle")
            }
            
            Spacer()
            
            // ソートボタン
            Menu {
                Menu("期限") {
                    Button("早い順") {
                        sortMode = .deadlineAsc
                    }
                    Button("遅い順") {
                        sortMode = .deadlineDesc
                    }
                }
                
                Menu("重要度") {
                    Button("高い順") {
                        sortMode = .priorityDesc
                    }
                    Button("低い順") {
                        sortMode = .priorityAsc
                    }
                }
                
                Menu("開始日時") {
                    Button("早い順") {
                        sortMode = .startDateTimeAsc
                    }
                    Button("遅い順") {
                        sortMode = .startDateTimeDesc
                    }
                }
                
                Menu("登録日時") {
                    Button("新しい順") {
                        sortMode = .createdAtDesc
                    }
                    Button("古い順") {
                        sortMode = .createdAtAsc
                    }
                }
            } label: {
                Label("ソート: \(sortMode.displayName)", systemImage: "arrow.up.arrow.down")
            }
        }
        .padding()
    }
}

