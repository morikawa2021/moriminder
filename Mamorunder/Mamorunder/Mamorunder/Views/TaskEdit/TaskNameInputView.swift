//
//  TaskNameInputView.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import SwiftUI

struct TaskNameInputView: View {
    @Binding var title: String
    @Binding var extractedDateTime: Date?
    @Binding var extractedTaskType: TaskType
    
    private let parser = NaturalLanguageParser()
    @State private var showExtractionAlert = false
    @State private var extractedResult: NaturalLanguageParser.ExtractionResult?
    
    var body: some View {
        TextField("タスク名", text: $title)
            .onChange(of: title) { newValue in
                parseNaturalLanguage(newValue)
            }
            .alert("日時を検出しました", isPresented: $showExtractionAlert) {
                Button("キャンセル", role: .cancel) {
                    extractedResult = nil
                }
                Button("適用") {
                    applyExtraction()
                }
            } message: {
                if let result = extractedResult,
                   let dateTime = result.dateTime {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "ja_JP")
                    formatter.calendar = Calendar(identifier: .gregorian)
                    formatter.dateFormat = "yyyy年M月d日(E) H:mm"
                    
                    let taskTypeText = result.taskType == .task ? "期限" : "開始日時"
                    return Text("\(taskTypeText): \(formatter.string(from: dateTime))\n\nこの日時を設定しますか？")
                }
                return Text("")
            }
    }
    
    private func parseNaturalLanguage(_ text: String) {
        let result = parser.extractDateTime(from: text)
        
        if let dateTime = result.dateTime {
            extractedResult = result
            showExtractionAlert = true
        }
    }
    
    private func applyExtraction() {
        guard let result = extractedResult,
              let dateTime = result.dateTime else { return }
        
        extractedDateTime = dateTime
        extractedTaskType = result.taskType ?? .task
        
        extractedResult = nil
    }
}

