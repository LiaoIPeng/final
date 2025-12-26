//
//  PhotoPagerView.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//


import SwiftUI
import PhotosUI
import UIKit

struct PhotoPagerView: View {
  @Environment(\.dismiss) private var dismiss

  let records: [PhotoRecord]
  let startIndex: Int

  @State private var selection: Int

  init(records: [PhotoRecord], startIndex: Int) {
    self.records = records
    self.startIndex = max(0, min(startIndex, records.count - 1))
    _selection = State(initialValue: max(0, min(startIndex, records.count - 1)))
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Color.black.ignoresSafeArea()

        if records.isEmpty {
          ContentUnavailableView("沒有照片", image: "photo")
        } else {
          TabView(selection: $selection) {
            ForEach(records.indices, id: \.self) { idx in
              let record = records[idx]
              VStack(spacing: 12) {
                if let uiImage = ImageStore.loadUIImage(filename: record.imageFilename) {
                  Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                  ContentUnavailableView("載入失敗", image: "photo")
                }

                Text("拍攝日期：\(record.shotDate.formatted(date: .abbreviated, time: .omitted))")
                  .font(.subheadline)
                  .foregroundStyle(.white.opacity(0.85))
                  .padding(.bottom, 16)
              }
              .padding(.horizontal)
              .tag(idx)
            }
          }
          .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
      }
      .navigationTitle(records.isEmpty ? "" : "\(selection + 1)/\(records.count)")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
              .foregroundStyle(.white)
          }
          .accessibilityLabel("關閉")
        }
      }
    }
  }
}
