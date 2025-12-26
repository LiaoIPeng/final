//
//  ProjectRowView.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//


import SwiftUI
import PhotosUI
import UIKit

struct ProjectRowView: View {
  let project: Project

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: project.symbolName)
        .imageScale(.large)

      VStack(alignment: .leading, spacing: 4) {
        Text(project.name)
          .font(.headline)

        Text(project.createdAt, style: .date)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}