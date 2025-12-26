//
//  ResultsRowView.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//


import SwiftUI
import PhotosUI
import UIKit

struct ResultsRowView: View {
  let project: Project

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: project.symbolName)
        .imageScale(.large)

      VStack(alignment: .leading, spacing: 4) {
        Text(project.name)
          .font(.headline)

        Text(project.category ?? "未分類")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Text(project.profit ?? 0, format: .number)
        .font(.headline)
    }
    .padding(.vertical, 4)
  }
}