//
//  TaskSubdivisionViewModel.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import SwiftUI
import CoreData
import Combine

struct SubdivisionProposal: Identifiable {
    let id = UUID()
    var title: String
    var isSelected: Bool
}

class TaskSubdivisionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var proposals: [SubdivisionProposal]?
    @Published var error: Error?
    
    private let task: Task
    private let viewContext: NSManagedObjectContext
    
    init(task: Task, viewContext: NSManagedObjectContext) {
        self.task = task
        self.viewContext = viewContext
    }
    
    // 細分化提案の生成（LLM API連携は後回し）
    func generateProposals() {
        isLoading = true
        error = nil
        
        // TODO: LLM API連携は後回し
        // 現時点ではプレースホルダーメッセージを表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            // プレースホルダー: 実際のLLM API連携は後で実装
            self.proposals = [
                SubdivisionProposal(title: "（細分化機能は準備中です）", isSelected: false)
            ]
        }
    }
    
    func toggleProposal(_ proposal: SubdivisionProposal, isSelected: Bool) {
        guard let index = proposals?.firstIndex(where: { $0.id == proposal.id }) else { return }
        proposals?[index].isSelected = isSelected
    }
    
    func approveProposals() {
        // TODO: 選択された提案をタスクとして作成
        // LLM API連携実装時に実装
    }
}







