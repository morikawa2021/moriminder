//
//  CategoryManagementViewModel.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import Foundation
import CoreData
import Combine

class CategoryManagementViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var categoryToDelete: Category?
    @Published var categoryToEdit: Category?
    @Published var editingName: String = ""
    @Published var editingColor: String = "#007AFF"
    @Published var showingColorPicker = false
    
    private let viewContext: NSManagedObjectContext
    private var categoryManager: CategoryManager {
        CategoryManager(viewContext: viewContext)
    }
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func loadCategories() {
        categories = categoryManager.fetchCategories()
    }
    
    func deleteCategory(_ category: Category) {
        do {
            try categoryManager.deleteCategory(category)
            loadCategories()
            NotificationCenter.default.post(name: NSNotification.Name("CategoriesDidChange"), object: nil)
        } catch {
            print("カテゴリ削除エラー: \(error)")
        }
    }
    
    func startEditing(_ category: Category) {
        categoryToEdit = category
        editingName = category.name ?? ""
        editingColor = category.color ?? "#007AFF"
    }
    
    func saveEditing() {
        guard let category = categoryToEdit else { return }
        
        do {
            if editingName != category.name {
                try categoryManager.updateCategoryName(category, name: editingName)
            }
            if editingColor != category.color {
                try categoryManager.updateCategoryColor(category, color: editingColor)
            }
            loadCategories()
            categoryToEdit = nil
            NotificationCenter.default.post(name: NSNotification.Name("CategoriesDidChange"), object: nil)
        } catch {
            print("カテゴリ更新エラー: \(error)")
        }
    }
    
    func cancelEditing() {
        categoryToEdit = nil
        editingName = ""
        editingColor = "#007AFF"
    }
    
    func getTaskCount(for category: Category) -> Int {
        return category.tasks?.count ?? 0
    }
}

