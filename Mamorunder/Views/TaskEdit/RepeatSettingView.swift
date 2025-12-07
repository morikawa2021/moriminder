//
//  RepeatSettingView.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import SwiftUI

struct RepeatSettingView: View {
    @Binding var enabled: Bool
    @Binding var pattern: RepeatPattern?
    @Binding var endDate: Date?
    
    var body: some View {
        Toggle("繰り返し", isOn: $enabled)
        
        if enabled {
            // TODO: 繰り返しパターンの選択UI
            Text("繰り返しパターン選択（実装予定）")
            
            DatePicker("終了日時", selection: Binding(
                get: { endDate ?? Date() },
                set: { endDate = $0 }
            ), displayedComponents: [.date, .hourAndMinute])
        }
    }
}

