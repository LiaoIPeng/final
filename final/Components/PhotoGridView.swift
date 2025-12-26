//
//  PhotoGridView.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//


import SwiftUI
import PhotosUI
import UIKit

struct PhotoGridView: View {
  let records: [PhotoRecord]
  var onTap: (Int) -> Void

  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12)
  ]

  init(records: [PhotoRecord], onTap: @escaping (Int) -> Void = { _ in }) {
    self.records = records
    self.onTap = onTap
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: 12) {
      ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
        Button {
          onTap(index)
        } label: {
          VStack(alignment: .leading, spacing: 6) {
            if let uiImage = ImageStore.loadUIImage(filename: record.imageFilename) {
              Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
              RoundedRectangle(cornerRadius: 12)
                .fill(.secondary.opacity(0.2))
                .frame(height: 140)
                .overlay {
                  Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                }
            }

            Text("拍攝日期：\(record.shotDate.formatted(date: .abbreviated, time: .omitted))")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .buttonStyle(.plain)
      }
    }
  }
}
