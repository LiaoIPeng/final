//
//  AddProjectSheet.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//


import SwiftUI
import PhotosUI
import UIKit

struct AddProjectSheet: View {
  @Environment(\.dismiss) private var dismiss

  @State private var name: String = ""
  @State private var category: String = ""
  @State private var symbolName: String = "leaf"

  private let symbolOptions: [String] = ["leaf", "tree", "camera.macro"]

  var onAdd: (Project) -> Void

  var body: some View {
    NavigationStack {
      Form {
        Section("專案資訊") {
          TextField("專案名稱（必填）", text: $name)
          TextField("分類（可選）", text: $category)

          Picker("圖示", selection: $symbolName) {
            ForEach(symbolOptions, id: \.self) { symbol in
              Image(systemName: symbol)
                .tag(symbol)
            }
          }
        }
      }
      .navigationTitle("新增專案")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("新增") {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
            let project = Project(
              name: trimmedName,
              category: trimmedCategory.isEmpty ? nil : trimmedCategory,
              symbolName: symbolName
            )
            onAdd(project)
            dismiss()
          }
          .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }
}