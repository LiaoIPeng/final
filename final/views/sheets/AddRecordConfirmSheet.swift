//
//  AddRecordConfirmSheet.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//


import SwiftUI
import PhotosUI
import UIKit

struct AddRecordConfirmSheet: View {
  @Environment(\.dismiss) private var dismiss

  @Binding var image: UIImage?
  @Binding var shotDate: Date

  var onSave: (UIImage, Date) -> Void
  var onCancel: () -> Void

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        if let img = image {
          Image(uiImage: img)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 260)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        } else {
          ContentUnavailableView("沒有選到照片", image: "leaf")
        }

        DatePicker("拍攝日期", selection: $shotDate, displayedComponents: .date)
          .datePickerStyle(.compact)
          .padding(.horizontal)

        Spacer(minLength: 0)
      }
      .padding(.top, 8)
      .navigationTitle("新增照片紀錄")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") {
            onCancel()
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("儲存") {
            guard let img = image else { return }
            onSave(img, shotDate)
            dismiss()
          }
          .disabled(image == nil)
        }
      }
    }
  }
}