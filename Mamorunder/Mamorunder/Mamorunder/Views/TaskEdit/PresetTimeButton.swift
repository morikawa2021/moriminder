//
//  PresetTimeButton.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import SwiftUI
import CoreData

struct PresetTimeButton: View {
    let preset: PresetTime
    let taskType: TaskType
    @Binding var deadline: Date?
    @Binding var startDateTime: Date?
    
    var body: some View {
        Button {
            applyPreset()
        } label: {
            Text(preset.name ?? "")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
    }
    
    private func applyPreset() {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = Int(preset.hour)
        dateComponents.minute = Int(preset.minute)
        
        if let baseDate = calendar.date(from: dateComponents) {
            let targetDate = calendar.date(byAdding: .day, value: Int(preset.offsetDays), to: baseDate) ?? baseDate
            
            if taskType == .task {
                deadline = targetDate
            } else {
                startDateTime = targetDate
            }
        }
    }
}

